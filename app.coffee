express = require 'express'
fs = require 'fs'
MemoryStore = require('express').session.MemoryStore
Mongoose = require 'mongoose'

UserModel = require './model/User'
AccountModel = require './model/Account'
passport = require 'passport'
LocalStrategy = require('passport-local').Strategy
FoursquareStrategy = require('passport-foursquare').Strategy


DB = process.env.DB || 'mongodb://localhost:27017/shop'
db = Mongoose.createConnection DB
User = UserModel db
UserController = require('./control/users')(User)

mongomate = require('mongomate')('mongodb://localhost');

Account = AccountModel db

DEV = false

if DEV
  FOURSQUARE_CLIENT_ID = "KSWWRPJI53P5LBXLXU2US0KHPDSPCFJKBINFF110OGI5SPAV"
  FOURSQUARE_CLIENT_SECRET = "HS0J4HEKNI4QANL2SNCE0G54GGSPJFSW5450J0410MZCNF1W"
  CALLBACK_URL = "http://127.0.0.1:3000/auth/foursquare/callback"
  PORT = 3000
else
  FOURSQUARE_CLIENT_ID = "KSWWRPJI53P5LBXLXU2US0KHPDSPCFJKBINFF110OGI5SPAV"
  FOURSQUARE_CLIENT_SECRET = "HS0J4HEKNI4QANL2SNCE0G54GGSPJFSW5450J0410MZCNF1W"
  CALLBACK_URL = "http://ec2-184-72-144-249.compute-1.amazonaws.com/auth/foursquare/callback"
  PORT = 80


FOURSQUARE_INFO = {
                    "clientID": FOURSQUARE_CLIENT_ID, 
                    "clientSecret": FOURSQUARE_CLIENT_SECRET, 
                    "callbackURL": CALLBACK_URL
                  }

exports.createServer = ->
  app = express()

  
  passport.serializeUser (account, done) ->
    done null, account.foursquareId

  
  passport.deserializeUser (id, done) ->
    Account.findById id, (err, user) ->
      done null, user

  
  passport.use new FoursquareStrategy FOURSQUARE_INFO, (accessToken, refreshToken, profile, done) ->
    process.nextTick ()->
      accountData = {foursquareId: profile.id, name: profile.name, gender: profile.gender, emails: profile.emails}
      account = new Account accountData
      account.save (err) ->
        return done(null, account)
  

  app.configure ->
    app.use(express.cookieParser())
    app.use(express.bodyParser())
    app.use(express.methodOverride())
    app.use(express.session({ secret: 'keyboard cat' }))
    app.use(passport.initialize())
    app.use(passport.session())
    app.use('/db', mongomate);
    
    app.set('view engine', 'jade')
    app.use(app.router)
    app.use(express.static(__dirname + "/public"))
    app.set('views', __dirname + '/public')

  app.get "/app", (req, res)->
    ensureAuthenticated req, res, ()->
      checkins = []
      for i in [0...20]
        checkins.push {name: "Jenny Moncur", location: "Burger King", time: "2012-12-05T12:12:12Z0000"} if (i % 1) == 0
        checkins.push {name: "Casey Moncur", location: "Burger King", time: "2012-12-05T12:12:12Z0000"} if (i % 2) == 0
        checkins.push {name: "Logan Moncur", location: "Burger King", time: "2012-12-05T12:12:12Z0000"} if (i % 3) == 0
        checkins.push {name: "Oliver Moncur", location: "Burger King", time: "2012-12-05T12:12:12Z0000"} if (i % 4) == 0

      res.render('app', {title: "Foursquare Checkins", checkins: checkins})


  app.get "/login", (req, res)->
    return res.redirect '/login/foursquare'
    #res.render('login', {title: "Driver Login"})


  app.get "/logout", (req, res)->
    res.session.user = null
    res.redirect '/login'

  app.post "/login", (req, res)->
    res.redirect "/login" unless (req.body.username? and req.body.password)
    user = {username: req.body.username, password: req.body.password}
    req.session.user = user
    res.redirect '/login/foursquare'

  app.get "/login/foursquare", (req, res) ->
    ensureUserAuthenticated req, res, ()->
      return res.redirect '/app' if req.isAuthenticated()
      res.render('login_foursquare', {title: "Foursquare Login"})

  app.get "/logout/foursquare", (req, res) ->
    req.logout()
    res.redirect '/logout/foursquare'

  app.get '/view/jade', (req, res) ->
    checkins = []
    for i in [0...5]
      checkins.push {name: "Jenny Moncur", location: "Burger King", time: "2012-12-05T12:12:12Z0000"} if (i % 1) == 0
      checkins.push {name: "Casey Moncur", location: "Burger King", time: "2012-12-05T12:12:12Z0000"} if (i % 2) == 0
      checkins.push {name: "Logan Moncur", location: "Burger King", time: "2012-12-05T12:12:12Z0000"} if (i % 3) == 0
      checkins.push {name: "Oliver Moncur", location: "Burger King", time: "2012-12-05T12:12:12Z0000"} if (i % 4) == 0

    res.render('login', {title: "Foursquare Checkins", checkins: checkins})

  app.get '/auth/foursquare', passport.authenticate('foursquare')


  app.get '/auth/foursquare/callback', passport.authenticate('foursquare', { failureRedirect: '/login' }), (req, res) ->
    res.redirect '/app'

  ###app.get '/', ensureAuthenticated, (req, res) ->
    res.json req.user###

  # final return of app object
  app

if module == require.main
  app = exports.createServer()
  app.listen PORT
  console.log "Running Foursquare Service"

ensureAuthenticated = (req, res, next)->
  ensureUserAuthenticated req, res, ()->
    ensureFoursquareAuthenticated req, res, next

ensureUserAuthenticated = (req, res, next)->
  return next() #if req.session.user?
  #res.redirect '/login'

ensureFoursquareAuthenticated = (req, res, next)->
  return next() if req.isAuthenticated()
  res.redirect '/login/foursquare'
