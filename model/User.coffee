mongoose = require 'mongoose'
Schema = mongoose.Schema

# User Model
module.exports = (db) ->

  UserSchema = new Schema {
    username: String,
    password: String
  }


  # Get All Users for a group
  UserSchema.statics.findById = (id, cb) ->
    @findOne({"_id": id}).exec cb

  # Get a user by id
  UserSchema.statics.findOrCreate = (data, cb) ->
    @findOne({"_id": data.foursquareId}).exec (err, user) ->



  User = db.model "User", UserSchema