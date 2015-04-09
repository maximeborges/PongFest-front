User = require "../models/user"
GameHelper = require "./game"

global.role = left: 0, right: 0

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
      if user.role == global.fictif.side
        if user.role == "right" and global.fictif.y > global.racket.right
          user.score--
        else if user.role == "right" and global.fictif.y < global.racket.right
          user.score++
        if user.role == "left" and global.fictif.y > global.racket.left
          user.score--
        else if user.role == "left" and global.fictif.y < global.racket.left
          user.score++
    else if input == 'down'
      GameHelper.down(user.role)
      if user.role == global.fictif.side
        if user.role == "right" and global.fictif.y < global.racket.right
          user.score--
        else if user.role == "right" and global.fictif.y > global.racket.right
          user.score++
        if user.role == "left" and global.fictif.y < global.racket.left
          user.score--
        else if user.role == "left" and global.fictif.y > global.racket.left
          user.score++
    else
      console.error('Input unknown')
    user.save (err) ->
      if err
        console.error("fail to save user" + user + ":" + err)
        res.status 500
        res.send "something wrong happened"

  wsMessage: (message) ->
    event = JSON.parse(message).data
    @find event.token, (error) ->
      console.error(error)
    , (user) ->
      if event.type == "input"
        UserHelper.direction(user, event.input)
      else
        console.error("Type unknown")
  giveRole: ->
    if global.role.left > global.role.right
      global.role.right++
      return "right"
    else
      global.role.left++
      return "left"
}

module.exports = UserHelper
