express = require 'express'
fs = require 'fs'
MemoryStore = require('express').session.MemoryStore
Mongoose = require 'mongoose'

UserModel = require './model/User'
AccountModel = require './model/Account'
passport = require 'passport'
LocalStrategy = require('passport-local').Strategy
FoursquareStrategy = require('passport-foursquare').Strategy

request = require "request"
https = require('https')

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
  CALLBACK_URL = "https://127.0.0.1:3000/auth/foursquare/callback"
  PORT = 3000
else
  FOURSQUARE_CLIENT_ID = "KSWWRPJI53P5LBXLXU2US0KHPDSPCFJKBINFF110OGI5SPAV"
  FOURSQUARE_CLIENT_SECRET = "HS0J4HEKNI4QANL2SNCE0G54GGSPJFSW5450J0410MZCNF1W"
  CALLBACK_URL = "https://ec2-184-72-144-249.compute-1.amazonaws.com/auth/foursquare/callback"
  PORT = 443


FOURSQUARE_INFO = {
                    "clientID": FOURSQUARE_CLIENT_ID, 
                    "clientSecret": FOURSQUARE_CLIENT_SECRET, 
                    "callbackURL": CALLBACK_URL
                  }

exports.createServer = ->
  privateKey = fs.readFileSync('./cert/server.key').toString();
  certificate = fs.readFileSync('./cert/server.crt').toString(); 

  app = express()

  server = https.createServer({key: privateKey, cert: certificate}, app).listen PORT, ()->
    console.log "Running Foursquare Service on port: " + PORT
  
  passport.serializeUser (account, done) ->
    done null, account.foursquareId

  
  passport.deserializeUser (id, done) ->
    Account.findById id, (err, user) ->
      done null, user

  
  passport.use new FoursquareStrategy FOURSQUARE_INFO, (accessToken, refreshToken, profile, done) ->
    process.nextTick ()->
      console.log profile._json.response.user.homeCity
      accountData = {foursquareId: profile.id, name: profile.name, gender: profile.gender, emails: profile.emails, token: accessToken, photo: profile._json.response.user.photo, homeCity: profile._json.response.user.homeCity}
      Account.findOrCreate accountData, done
  

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
    app.use('/javascript', express.static(__dirname + "/public/javascript"))


  app.get '/', (req, res)->
    res.redirect '/app'

  app.get "/app", (req, res)->
    ensureAuthenticated req, res, ()->
      res.redirect '/profile/' + req.session.account.foursquareId


  app.get '/profile/:user_id', (req, res)->
    Account.findById req.params.user_id, (err, user)->
      limit = 1
      if req.session?.account? && req.params.user_id == req.session.account.foursquareId
        limit = 10
      options = 
        url: 'https://api.foursquare.com' + '/v2/users/'+req.params.user_id+'/checkins?oauth_token='+user.token+'&limit=' + limit
        json: true
      request options, (error, response, body)->
        console.log JSON.stringify body
        res.render 'profile', {checkins: body.response.checkins.items, user: user, title: "Profile", logged_in: limit == 10}




  app.get "/profiles", (req, res)->
    Account.getAllAccounts (err, accounts)->
      logged_in = false
      if req.session?.account?
        logged_in = true
      res.render('profiles', {users: accounts, title: "Users", logged_in: logged_in})

  app.get "/login", (req, res)->
    #return res.redirect '/login/foursquare'
    res.render('login', {title: "Login"})


  app.get "/logout", (req, res)->
    if req.session?.user?
      delete req.session.user
    req.logout()
    res.redirect '/login'

  app.post "/login", (req, res)->
    res.redirect "/login" unless (req.body.username? and req.body.password)
    data = {username: req.body.username, password: req.body.password}
    User.findOrCreate data, (err, user, created)->
      req.session.user = user
      if created or not user.foursquareId?
        return res.redirect '/login/foursquare'
      Account.findById user.foursquareId, (err, account)->
        return res.redirect '/login/foursquare' if err? or not account?
        req.session.account = account
        console.log "Redirect /app"
        res.redirect '/app'
       

  app.get "/login/foursquare", (req, res) ->
    console.log "Redirect received /login/foursquare"
    ensureUserAuthenticated req, res, ()->
      return res.redirect '/app' if req.session?.account?
      res.render('login_foursquare', {title: "Foursquare Login"})

  app.get "/logout/foursquare", (req, res) ->
    req.logout()
    res.redirect '/login/foursquare'

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
    req.session.account = req.user
    req.session.user.foursquareId = req.user.foursquareId
    User.addAccount req.user.foursquareId, req.session.user.username, ()->
      res.redirect '/app'

  # final return of app object
  app

if module == require.main
  app = exports.createServer()
  app.listen 80
  

ensureAuthenticated = (req, res, next)->
  ensureUserAuthenticated req, res, ()->
    ensureFoursquareAuthenticated req, res, next

ensureUserAuthenticated = (req, res, next)->
  return next() if req.session?.user?
  res.redirect '/login'

ensureFoursquareAuthenticated = (req, res, next)->
  console.log JSON.stringify req.user
  return next() if req.session?.account?
  res.redirect '/login/foursquare'
