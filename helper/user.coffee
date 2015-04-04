User = require "../models/user"
GameHelper = require "./game"

UserHelper = {
  find: (token, errorCallback, callback) ->
    User.find token: token, (err, users) ->
      if err
        console.error(err)
        return errorCallback type: "internal"
      if users.length == 0
        return errorCallback type: "not found"
      callback users[0]

  direction: (user, input) ->
    if input == 'up'
      GameHelper.up(user.role)
    else if input == 'down'
      GameHelper.down(user.role)
    else
      console.error('Input unknown')
    #todo: mettre un score à l'utilisateur

  wsMessage: (message) ->
    event = JSON.parse(message)
    @find event.token, (error) ->
      console.error(error)
    , (user) ->
      if event.type == "input"
        UserHelper.direction(user, event.input)
      else
        console.error("Type unknown")
}

module.exports = UserHelper
