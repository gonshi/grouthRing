EventDispatcher = require "../util/eventDispatcher"
Throttle = require "../util/throttle"
instace = null
  
class MouseHandler extends EventDispatcher
  constructor: -> super()

  exec: ->
    throttle = new Throttle 10
    is_draw = null

    $( document ).on "mousemove", ( e )=>
      if is_draw
        throttle.exec => @dispatch "MOUSE_DRAGED", this, e
      else
        throttle.exec => @dispatch "MOUSE_MOVED", this, e

    $( document ).on "click", ( e )=>
      if is_draw == null
        is_draw = true
      else if is_draw
        @dispatch "DRAW_END", this
        is_draw = false
      # 1度trueになったら2度目以降のclickではtrueにならない

  off: -> $( document ).off "mousemove"

getInstance = ->
  if !instance
    instance = new MouseHandler()
  return instance

module.exports = getInstance
