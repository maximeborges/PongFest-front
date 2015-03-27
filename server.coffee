# Entrypoint of the service
#

WebSocketServer = require("websocket").server
express = require "express"
app = express()

app.use express.static(__dirname + '/public')

mongoose = require 'mongoose'
mongoose.connect process.env.MONGO_URL || 'mongodb://localhost/shadok-api'

db = mongoose.connection
db.on 'error', console.error.bind(console, 'connection error:')
db.once 'open', (callback) ->
  console.log("connection opened")

userSchema = mongoose.Schema({
  first_name: String
  last_name: String
  facebook_token: String
})
User = mongoose.model("User", userSchema)

app.use (req, res, next) ->
  console.log(req.path)
  next(req, res)

# Homepage
app.post "/users", (req, res) ->
  user = new User facebook_token: req.body.user.facebook_token
  req.send(user)

app.patch "/users/:facebook_token", (req, res) ->
  User.find facebook_token: req.params.facebook_token

app.get "/leaderboard", (req, res) ->
  req.send("leaderboard")

# From laser server
app.post "/score", (req, res) ->
  req.send("score")

server = app.listen process.env.PORT || 3000, () ->
  host = server.address().address
  port = server.address().port
  console.log 'App listening at http://%s:%s', host, port

wss = new WebSocketServer server: server, path: "/ws"

wss.on 'request', (request) ->
  connection = request.accept null, request.origin ->
    connection.on 'message', (message) ->
      event = JSON.parse(message)
      console.log(event)

    connection.on 'close', (connection) ->
      console.log(connection)
