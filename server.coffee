#
# Entrypoint of the service
#
randtoken = require "rand-token"
http = require "http"
express = require "express"
bodyParser = require 'body-parser'

User = require "./models/user"
UserHelper = require "./helper/user"

GameHelper = require "./helper/game"

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

totalPlayers = 0
wsClients = []
score = {left: 0, right: 0}
global.role.left = 0
global.role.right = 0

# Homepage
app.get "/", (req, res) ->
  res.render "index"

# TODO
app.get "/api/leaderboard", (req, res) ->
  res.send "leaderboard"

app.get "/api/top100", (req, res) ->
  User
    .find {"score":{$exists:true}}
    .sort {"score":-1}
    .limit(100)
    .exec (err, users) ->
      res.status 200
      res.json users

app.get "/api/flop100", (req, res) ->
  User
    .find {"score":{$exists:true}}
    .sort {"score":1}
    .limit(100)
    .exec (err, users) ->
      res.status 200
      res.json users


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

# From laser game
#
# Expect
# {
#   "side":  <left or right>,
#   "y": <int>
# }
app.post "/api/racket", (req, res) ->
  if req.body.side == "right"
    global.racket.right = req.body.y
    res.status 204
    res.send ""
  else if req.body.side == "left"
    global.racket.left = req.body.y
    res.status 204
    res.send ""
  else
    res.status 400
    res.send "Side unknown"
    console.error("Side unknown: " + global.racket.side)
  
# From laser game
#
# Expect
# {
#   "side": <left or right>,
#   "y": <int>
# }
app.post "/api/fictif", (req, res) ->
  if req.body.side not in ['left', 'right']
    res.status 400
    res.send "Side unknown"
  else
    global.fictif = req.body
    res.status 204
    res.send ""



app.ws '/ws', (ws, req) ->
  wsClients.push(ws)
  userToken = null
  ws.send JSON.stringify({event: "score", data: score})
  ws.send JSON.stringify({event: "players", data: {left: global.role.left, right: global.role.right, total: totalPlayers}})

  # ping every 15 secs
  pingIntervalId = setInterval () ->
    ws.send JSON.stringify({event: "ping", data: {ts: new Date().getTime()}})
  , parseInt(process.env.WS_PING_DELAY) || 15000

  ws.on 'message', (message) ->

    

    message = JSON.parse message
    event = message.event
    data = message.data

    if event == 'createUser'
      #
      # Expect
      # {
      #    "id": "<id facebook, generated if null>",
      #    "firstName": "<first name, given by facebook API>",
      #    "lastName": "<last name, given by facebook API>"
      #    "name": "<username if facebook not used>"
      # }
      #
      token = data.id
      name = data.name || data.firstName + " " + data.lastName

      creation = (ws, message, event, data) ->
        token = data.id
        name = data.name || data.firstName + " " + data.lastName
        console.log "Creating a new user "+name

        if !token
          token = randtoken.generate(16)

        userToken = token

        
        role = UserHelper.giveRole()
        user = new User token: token, name: name, role: role, score: 0
        user.save (err) ->
          if err
            console.error("fail to save user" + user + ":" + err)
            ws.send JSON.stringify({event: 'user', data: err})
          else
            totalPlayers++
            ws.send JSON.stringify({event: 'user', data: user})
            wsClients.forEach (client) ->
              if client.readyState == 1
                client.send JSON.stringify({event: "players", data: {left: global.role.left, right: global.role.right, total: totalPlayers}})
                client.send JSON.stringify({event: "notification", data: {user: user, type: 'connect'}})

      if !token
        User.find {"name": name}, (err, user) ->
          if user.length > 0
            console.log 'User '+name+" already exists"
            ws.send JSON.stringify({event: 'user', data: user[0]})
          else
            creation ws, message, event, data
      else
        User.find {"token": token}, (err, user) ->
          if user.length > 0
            console.log 'Facebook user '+name+" already exists"
            ws.send JSON.stringify({event: 'user', data: user[0]})
          else
            creation ws, message, event, data



    else
      UserHelper.find data.token
      , (error) ->
          console.error(error)
      , (user) ->
        if event == "input"
          #
          # Expect
          # {
          #   "token": "<user token for auth>"
          #   "input": "<up or down>"
          # }
          #
          UserHelper.direction(user, data.input)
        else
          console.error("Unknown message")

  ws.on 'close', (e) ->
    # Remove disconnected user
    wsClients.splice(wsClients.indexOf(ws), 1)
    clearInterval pingIntervalId

    UserHelper.find userToken
    , (err) ->
      console.log(err)
    , (user) ->
      console.log('disconnection from '+ user.role)
      if user.role == 'left'
        global.role.left--
      else
        global.role.right--
      wsClients.forEach (client) ->
        if client.readyState == 1 # Websocket opened
          client.send JSON.stringify({event: "players", data: {left: global.role.left, right: global.role.right, total: totalPlayers}})
          client.send JSON.stringify({event: "notification", data: {user: user, type: 'disconnect'}})


server = app.listen process.env.PORT || 3000, () ->
  host = server.address().address
  port = server.address().port
  console.log 'App listening at http://%s:%s', host, port
