mongoose = require 'mongoose'
Schema = mongoose.Schema

# User Model
module.exports = (db) ->

  UserSchema = new Schema {
    username: String,
    password: String,
    foursquareId: String
  }


  # Get All Users for a group
  UserSchema.statics.addAccount = (foursquareId, username, cb) ->
    @findOne({"username": username}).exec (err, user)->
      user.foursquareId = foursquareId
      user.save()
      cb()

  # Get a user by id
  UserSchema.statics.findOrCreate = (data, cb) ->
    @findOne({"username": data.username}).exec (err, user) ->
      return cb {error: "Database Error"} if err?
      if not user?
        user = new User data
        user.save (err) ->
          return cb(null, user)
      else
        cb null, user


  User = db.model "User", UserSchema