class CanvasManager
  constructor: ( $dom )->
    @canvas = $dom.get 0
    if !@canvas.getContext
      return undefined
    @ctx = @canvas.getContext "2d"
    @ctx.strokeStyle = "#000"
    @lineWidth = 1

  resetContext: ( width, height )->
    @canvas.width = width
    @canvas.height = height

  clear: -> @ctx.clearRect 0, 0, @canvas.width, @canvas.height

  drawImg: ( img, x, y )->
    @ctx.drawImage img, x, y, @canvas.width, @canvas.height,
                   0, 0, @canvas.width, @canvas.height
  
  drawLine: ( to_x, to_y, from_x, from_y )->
    @ctx.beginPath()
    @ctx.moveTo from_x, from_y
    @ctx.lineTo to_x, to_y
    @ctx.lineWidth = @lineWidth
    @ctx.stroke()

  setLineWidth: ( width )-> @lineWidth = width

  getImgData: ( x, y, width, height )->
    @ctx.getImageData x, y, width, height

  getImg: -> @canvas.toDataURL()

  getContext: -> @ctx

module.exports = CanvasManager
