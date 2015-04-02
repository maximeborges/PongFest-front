mongoose = require 'mongoose'

userSchema = mongoose.Schema
  name: String
  token: String
  role: String

User = mongoose.model("User", userSchema)

module.exports = User
