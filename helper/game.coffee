dgram = require 'dgram'

global.tabLeft = up: 0, down: 0
global.tabRight = up: 0, down: 0

GameHelper = {
  up: (role) ->
    if role == "left"
      global.tabLeft.up++
    else if role == "right"
      global.tabRight.up++
    else
      console.error("Role unknown")
  down: (role) ->
    if role == "left"
      global.tabLeft.down++
    else if role == "right"
      global.tabRight.down++
    else
      console.error("Role unknown")
  sendDirection: ->
    keysbinLeft = 0
    keysbinRight = 0
    if global.tabLeft.up > global.tabLeft.down
      keysbinLeft += 16
    else
      keysbinLeft += 32
    if global.tabRight.up > global.tabRight.down
      keysbinRight += 16
    else
      keysbinRight += 32
    global.tabLeft.up = 0
    global.tabLeft.down = 0
    global.tabRight.up = 0
    global.tabRight.down = 0

    message = new Buffer(3)
    message.write('I', 0, 1, 'ascii')
    message.writeUInt8(keysbinLeft, 1)
    message.writeUInt8(keysbinRight, 2)
    console.log(JSON.stringify(message))
    client = dgram.createSocket("udp4")
    client.send(message, 0, message.length, 4242, "localhost")
    
}

setInterval(GameHelper.sendDirection, 1000)

module.exports = GameHelper
