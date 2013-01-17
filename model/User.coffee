mongoose = require 'mongoose'
Schema = mongoose.Schema

# User Model
module.exports = (db) ->

  UserSchema = new Schema {
    foursquareId: {type: String, required:true, unique: true},
    name: String,
    gender: String,
    emails: [String]
  }


  # Get All Users for a group
  UserSchema.statics.findById = (id, cb) ->
    @where("id").in(id).exec cb

  # Get a user by id
  UserSchema.statics.findOrCreate = (data, cb) ->
    @findOne({"foursquareId": data.foursquareId}).exec (err, user) ->



  User = db.model "User", UserSchema