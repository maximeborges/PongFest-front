# Entrypoint of the service
#

WebSocketServer = require("websocket").server
randtoken = require "rand-token"
http = require "http"
express = require "express"
app = express()

app.use express.static(__dirname + '/public')

mongoose = require 'mongoose'
mongoose.connect process.env.MONGO_URL || 'mongodb://localhost/shadok-api'

db = mongoose.connection
db.on 'error', console.error.bind(console, 'connection error:')
db.once 'open', (callback) ->
  console.log("connection to database opened")

wsClients = []

userSchema = mongoose.Schema({
  name: String
  token: String
  role: String
})

User = mongoose.model("User", userSchema)

app.use (req, res, next) ->
  console.log(new Date() + " " + req.path)
  next()

# Homepage
app.post "/users", (req, res) ->
  token = req.body.id
  if !token
    token = randtoken.generate(16)

  name = req.body.name || req.body.firstName + " " + req.body.lastName
  user = new User token: token, name: name
  user.save (err) ->
    console.error("fail to save user" + user + ":" + err) if err
    res.send user

app.patch "/users/:token", (req, res) ->
  User.find token: req.params.token, (err, users) ->
    if err
      console.error(err)
      req.status 500
      res.send "internal error"
      return

    if users.length == 0
      req.status 404
      res.send "not found"
      return

    user = users[0]
    user.role = req.body.role
    user.save (err) ->
      if err
        console.error("fail to update user" + user + ":" + err)
        req.status 500
        res.send "internal error"
        return
      res.send user

app.get "/leaderboard", (req, res) ->
  res.send "leaderboard"

# From laser server
app.post "/score", (req, res) ->
  score = {left: req.body.left, right: req.body.right}
  wsClients.forEach (client) ->
    client.send {event: "score", score: score}

server = http.createServer app
server.listen process.env.PORT || 3000, () ->
  host = server.address().address
  port = server.address().port
  console.log 'App listening at http://%s:%s', host, port

wss = new WebSocketServer httpServer: server, path: "/ws"

wss.on 'request', (request) ->
  connection = request.accept null, request.origin ->
    wsClients.push(connection)
    connection.on 'message', (message) ->
      event = JSON.parse(message)
      console.log(event)

    connection.on 'close', (connection) ->
      console.log(connection)
