mongoose = require 'mongoose'
Schema = mongoose.Schema

# User Model
module.exports = (db) ->

  AccountSchema = new Schema {
    foursquareId: {type: String, required:true, unique: true},
    name: {familyName: String, givenName: String},
    gender: String,
    emails: [{value: String}],
    user_id: String
  }


  # Get All Users for a group
  AccountSchema.statics.findById = (id, cb) ->
    @findOne({"foursquareId": id}).exec cb

  # Get a user by id
  AccountSchema.statics.findOrCreate = (data, cb) ->
    @findOne({"foursquareId": data.foursquareId}).exec (err, user) ->



  Account = db.model "Account", AccountSchema