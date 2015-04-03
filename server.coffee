#
# Entrypoint of the service
#

randtoken = require "rand-token"
http = require "http"
express = require "express"
bodyParser = require 'body-parser'

User = require "./models/user"
UserHelper = require "./helper/user"

app = express()
app.set 'view engine', 'jade'
app.use express.static(__dirname + '/public')
require('express-ws')(app)

app.use bodyParser.json()
app.use (req, res, next) ->
  console.log(new Date() + " - " + req.ip + " - " + req.path)
  next()

mongoose = require 'mongoose'
mongoose.connect process.env.MONGO_URL || 'mongodb://localhost/shadok-api'

db = mongoose.connection
db.on 'error', console.error.bind(console, 'connection error:')
db.once 'open', (callback) ->
  console.log "connection to database opened"

wsClients = []

# Homepage
app.get "/", (req, res) ->
  res.render "index"

# Create a new user
# {
#    "id": "<id facebook, generated if null>",
#    "firstName": "<first name, given by facebook API>",
#    "lastName": "<last name, given by facebook API>"
#    "name": "<username if facebook not used>"
# }
#
# Ths ID is used as token (it completely unsecured but ok for this hacking session)
#
# Returns
# {
#   "token": "<id facebook or generated token>",
#   "name": "<user name>"
# }
app.post "/api/users", (req, res) ->
  token = req.body.id
  if !token
    token = randtoken.generate(16)

  name = req.body.name || req.body.firstName + " " + req.body.lastName
  user = new User token: token, name: name
  user.save (err) ->
    if err
      console.error("fail to save user" + user + ":" + err)
      res.status 500
      res.send "something wrong happened"
    else
      res.send JSON.stringify(user)

# Patch a user
#
# Used to select the team
#
# Expect
# {
#   "role": "<left or right>"
# }
# Returns
# {
#   "token": "<id facebook or generated token>",
#   "name": "<user name>",
#   "role": "<role>",
# }
app.patch "/api/users/:token", (req, res) ->
  UserHelper.find req.params.token, (error) ->
    console.error(error)
    if error.type == "internal"
      res.status 500
      res.send "internal error"
    else if error.type == "not found"
      res.status 404
      res.send "not found"
  , (user) ->
    user.role = req.body.role
    user.save (err) ->
      if err
        console.error("fail to update user" + user + ":" + err)
        res.status 500
        res.send "internal error"
        return
      res.send JSON.stringify(user)

# TODO
app.get "/api/leaderboard", (req, res) ->
  res.send "leaderboard"

# From laser game
#
# Expect
# {
#   "left": <int>,
#   "right": <int>
# }
app.post "/api/score", (req, res) ->
  score = {left: req.body.left, right: req.body.right}
  wsClients.forEach (client) ->
    client.send JSON.stringify({event: "score", score: score})
  res.status 204
  res.send ""

app.ws '/ws', (ws, req) ->
  wsClients.push(ws)
    #
    # Expect
    # {
    #   "type": "input",
    #   "token": "<user token for auth>"
    #   "input": "<up or down>"
    # }
    #
  ws.on 'message', (message) ->
    UserHelper.wsMessage(message)

  ws.on 'close', (ws) ->
    console.log(ws)

  
server = app.listen process.env.PORT || 3000, () ->
  host = server.address().address
  port = server.address().port
  console.log 'App listening at http://%s:%s', host, port

