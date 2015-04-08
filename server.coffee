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
score = {left: 0, right: 0}

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
#   "name": "<user name>",
#   "role": "<role>"
# }
app.post "/api/users", (req, res) ->
  token = req.body.id
  if !token
    token = randtoken.generate(16)

  name = req.body.name || req.body.firstName + " " + req.body.lastName
  role = UserHelper.giveRole()
  user = new User token: token, name: name, role: role
  user.save (err) ->
    if err
      console.error("fail to save user" + user + ":" + err)
      res.status 500
      res.send "something wrong happened"
    else
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
    client.send JSON.stringify({event: "score", data: score})
  res.status 204
  res.send ""

app.ws '/ws', (ws, req) ->
  wsClients.push(ws)
  ws.send JSON.stringify({event: "score", data: score})

  # ping every 20 secs
  pingIntervalId = setInterval () ->
    ws.send JSON.stringify({event: "ping", data: {ts: new Date().getTime()}})
  , parseInt(process.env.WS_PING_DELAY) || 20000
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
    # Remove disconnected user
    clearInterval pingIntervalId
    wsClients.splice(wsClients.indexOf(ws), 1)
  
server = app.listen process.env.PORT || 3000, () ->
  host = server.address().address
  port = server.address().port
  console.log 'App listening at http://%s:%s', host, port
