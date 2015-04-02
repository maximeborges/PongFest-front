mongoose = require 'mongoose'

userSchema = mongoose.Schema
  name: String
  token: String
  role: String
  score: Number

User = mongoose.model("User", userSchema)

module.exports = User
