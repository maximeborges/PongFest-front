# Entrypoint of the service
#

WebSocketServer = require("websocket").server
FB = require 'fb'
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
  console.log(req.path)
  next(req, res)

# Homepage
app.post "/users", (req, res) ->
  token = req.body.token
  if !token
    token = randtoken.generate(16)
    name = req.body.name
    user = new User token: token, name: name
    req.send user
  else
    FB.setAccessToken(token)
    FB.api 'me', { fields: ['id', 'name'] }, (res) ->
      if res or res.error
        console.log(!res ? 'error occurred' : res.error)
        return

      console.log res.id
      console.log res.name
      user = new User token: token, name: name
      user.save (err) ->
        console.error("fail to save user" + user + ":" + err) if err
        res.send user

app.patch "/users/:facebook_token", (req, res) ->
  User.find token: req.params.token, (err, users) ->
    console.error(err) if err
    console.error("user not found " + token) if users.length == 0
    user = users[0]
    user.role = req.body.role
    user.save (err) ->
      console.error("fail to update user" + user + ":" + err) if err

app.get "/leaderboard", (req, res) ->
  req.send("leaderboard")

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
