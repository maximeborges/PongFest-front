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
    if global.tabLeft.up == 0 and global.tabLeft.down == 0
      keysbinLeft = 0
    else
      if global.tabLeft.up > global.tabLeft.down 
        keysbinLeft = 32
      else
        keysbinLeft = 16
    if global.tabRight.up == 0 and global.tabRight.down == 0
      keysbinRight = 0
    else
      if global.tabRight.up > global.tabRight.down
        keysbinRight = 32
      else
        keysbinRight = 16
    global.tabLeft.up = 0
    global.tabLeft.down = 0
    global.tabRight.up = 0
    global.tabRight.down = 0

    message = new Buffer(4)
    message.writeUInt8(255, 0)
    message.write('I', 1, 2, 'ascii')
    message.writeUInt8(keysbinRight, 2)
    message.writeUInt8(keysbinLeft, 3)

    client = dgram.createSocket("udp4")
    client.send(message, 0, message.length, parseInt(process.env.LASER_PORT) || 4242, process.env.LASER_URL || 'localhost')
    
}

setInterval(GameHelper.sendDirection, 500)

module.exports = GameHelper
