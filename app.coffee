express = require 'express'
fs = require 'fs'
MemoryStore = require('express').session.MemoryStore
Mongoose = require 'mongoose'
UserController = require './control/users'
User = require './model/User'
passport = require 'passport'
LocalStrategy = require('passport-local').Strategy
FoursquareStrategy = require('passport-foursquare').Strategy


DB = process.env.DB || 'mongodb://localhost:27017/moncurflix'
db = Mongoose.createConnection DB
user = User db
userController = UserController user

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
  app = express.createServer()

  
  passport.serializeUser (user, done) ->
    done null, user

  
  passport.deserializeUser (obj, done) ->
      done null, obj

  
  passport.use new FoursquareStrategy FOURSQUARE_INFO, (accessToken, refreshToken, profile, done) ->
    process.nextTick ()->
      return done(null, profile)
  

  app.configure ->
    app.use(express.cookieParser())
    app.use(express.bodyParser())
    app.use(express.methodOverride())
    app.use(express.session({ secret: 'keyboard cat' }))
    app.use(passport.initialize())
    app.use(passport.session())
    
    app.use(app.router)
    app.use(express.static(__dirname + "/public"))

  app.get "/app", (req, res) ->
    fs.readFile './public/index.html', (err, content) ->
      console.log content
      res.contentType ".html"
      res.send content


  app.get "/login", (req, res) ->
    fs.readFile './public/login.html', (err, content) ->
      console.log content
      res.contentType ".html"
      res.send content


  app.get '/auth/foursquare', passport.authenticate('foursquare')


  app.get '/auth/foursquare/callback', passport.authenticate('foursquare', { failureRedirect: '/login' }), (req, res) ->
    res.redirect '/app'

  # final return of app object
  app

if module == require.main
  app = exports.createServer()
  app.listen PORT
  console.log "Running Foursquare Service"