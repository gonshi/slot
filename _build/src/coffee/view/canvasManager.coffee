class CanvasManager
  constructor: ( $dom )->
    @canvas = $dom.get 0
    if !@canvas.getContext
      alert "This browser doesn\'t supoort HTML5 Canvas."
      return undefined

    @context = @canvas.getContext "2d"

  resetContext: ( width, height )->
    @canvas.width = width
    @canvas.height = height

  clear: ->
    @context.clearRect 0, 0, @canvas.width, @canvas.height

  drawTxt: ( x, y, txt )->
    @context.fillStyle = "#ffffff"
    @context.fillText txt, x, y

  drawAreaClip: ( id, plot )->
    ###
    #  {
    #    plot( { x1, y1, x2, y2, x3, y3, x4, y4 } )
    #  }
    ###

    _draw_x = Math.min( plot.x1, plot.x4 )
    _draw_y = Math.min( plot.y1, plot.y2 )
    _width = Math.max( plot.x2, plot.x3 ) - _draw_x
    _height = Math.max( plot.y3, plot.y4 ) - _draw_y

    @context.save()
    @context.beginPath()
    @context.moveTo plot.x1, plot.y1
    @context.lineTo plot.x2, plot.y2
    @context.lineTo plot.x3, plot.y3
    @context.lineTo plot.x4, plot.y4
    @context.closePath()
    @context.clip()
    @context.fillStyle = "rgb(#{ id }, 0, 0)"
    @context.fillRect _draw_x, _draw_y, _width, _height
    @context.restore()

  drawImgClip: ( img, original_plot, mask_plot, hover )->
    ###
    #  {
    #    img,
    #    plot( { x1, y1, x2, y2, x3, y3, x4, y4 } )
    #  }
    #
    #  1 -------- 2
    #  |          |
    #  |          |
    #  |          |
    #  4 -------- 3
    ###

    _img_ratio = img.height / img.width

    _clip_width = Math.max( original_plot.x2, original_plot.x3 ) -
                  Math.min( original_plot.x1, original_plot.x4 )
    _clip_height = Math.max( original_plot.y3, original_plot.y4 ) -
                   Math.min( original_plot.y1, original_plot.y2 )

    _clip_ratio = _clip_height / _clip_width

    if _img_ratio > _clip_ratio
      _draw_width = _clip_width
      _draw_height = _clip_width * _img_ratio
      _draw_x = Math.min( original_plot.x1, original_plot.x4 )
      _draw_y = Math.min( original_plot.y1, original_plot.y2 ) -
                ( _draw_height - _clip_height ) / 2
    else
      _draw_width = _clip_height / _img_ratio
      _draw_height = _clip_height
      _draw_x = Math.min( original_plot.x1, original_plot.x4 ) -
                ( _draw_width - _clip_width ) / 2
      _draw_y = Math.min( original_plot.y1, original_plot.y2 )

    @context.save()
    @context.beginPath()
    @context.moveTo mask_plot.x1, mask_plot.y1
    @context.lineTo mask_plot.x2, mask_plot.y2
    @context.lineTo mask_plot.x3, mask_plot.y3
    @context.lineTo mask_plot.x4, mask_plot.y4
    @context.closePath()
    @context.clip()
    @context.drawImage img, _draw_x, _draw_y,
                       _draw_width, _draw_height
    if hover?
      @context.fillStyle = "rgba(0, 0, 0, 0.7)"
      # +10 はcanvas bug fix
      @context.fillRect _draw_x, _draw_y, _draw_width, _draw_height + 10
    @context.restore()

  drawMaskedImg: ( drawImg, maskImg, x, y, width, height )->
    @resetContext @canvas.width, @canvas.height
    @clear()
    @context.drawImage maskImg, x, y, width, height
    @context.globalCompositeOperation = "source-in"
    @context.drawImage drawImg, x, y, width, height

  getImgData: ( x, y, width, height )->
    @context.getImageData x, y, width, height

module.exports = CanvasManager
