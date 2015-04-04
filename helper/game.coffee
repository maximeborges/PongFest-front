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
    if global.tabLeft.up > global.tabLeft.down
      moveLeft = "up"
    else
      moveLeft = "down"
    if global.tabRight.up > global.tabRight.down
      moveRight = "up"
    else
      moveRight = "down"
}

setInterval(GameHelper.sendDirection, 500)

module.exports = GameHelper
