User = require "../models/user"

UserHelper = {
  find: (token, errorCallback, callback) ->
    User.find token: token, (err, users) ->
      errorCallback type: "not found"
      # TODO by JEAN
}

module.exports = UserHelper
