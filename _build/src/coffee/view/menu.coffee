ticker = require( "../util/ticker" )()
CanvasManager = require( "../view/canvasManager" )
mouseMoveHandler = require( "../controller/mouseMoveHandler" )()
instace = null
  
class Menu extends EventDispatcher
  ############################################################
  # PRIVATE
  ############################################################
  _slideOut = ( callback )->
    return if !@PLOT?
    # 選択画面のスライドアウト
    @$select_txt.hide()
    _count = 0
    _duration = 25
    _gap = 5
    _count_max = _duration + _gap * ( @PIC_NAME.length - 1 )
    _order = [ 0, 2, 1, 3 ]

    ticker.clear "slidein_pic"
    ticker.listen "slideout_pic", =>
      _percent = 100 - window.easeOutQuad( _count, 0, 100, _count_max )
      @$subTtl_container.css opacity: _percent / 100

      @clearPic()
      # draw Masked Img
      for i in [ 0...@PIC_NAME.length ]
        continue if _count > _gap * _order[ i ] + _duration
        if _count < _gap * _order[ i ]
          @drawMaskedPic i, 100
        else
          _percent = 100 - window.easeOutQuad( _count - _gap * _order[ i ],
                                               0, 100, _duration )
          @drawMaskedPic i, _percent

      if _count == _count_max
        ticker.clear "slideout_pic"
        @$select_fixed.hide()
        callback() if callback?
      _count += 1

  _slideIn = ( callback )->
    return if @cur_anchor != @ANCHOR_LENGTH - 1
    # 選択画面のスライドイン
    @setPlot @winWidth, @win_height, 0
    _count = 0
    _duration = 30
    _gap = 10
    _count_max = _duration * 2 + _gap * ( @PIC_NAME.length - 1 )
    _order = [ 0, 2, 1, 3 ]

    @clearPic()
    ticker.clear "slideout_pic"
    ticker.listen "slidein_pic", =>
      _percent = window.easeOutQuad( _count, 0, 100, _count_max )
      @$subTtl_container.css opacity: _percent / 100

      # draw Masked Img
      for i in [ 0...@PIC_NAME.length ]
        continue if _count < _gap * _order[ i ]
        if _count <= _duration + _gap * _order[ i ] # monochrome
          _percent = window.easeOutQuad( _count - _gap * _order[ i ],
                                         0, 100, _duration )
          @drawMaskedPic i, _percent, true # mono
        else if _count <= _duration * 2 + _gap * _order[ i ] # color
          _percent = window.easeOutQuad( _count - _gap * _order[ i ] -
                                         _duration, 0, 100, _duration )
          @drawMaskedPic i, _percent
        else
          @drawMaskedPic i, 100

      if _count == _count_max
        ticker.clear "slidein_pic"
        @drawPic @winWidth, @win_height, 0 # draw 100% picture
        @$select_txt.show()
        mouseMoveHandler.listen "MOUSEMOVED", ( x, y )=> @checkArea x, y
        callback() if callback?
      _count += 1

  constructor: ->
    #####################################
    # DECLARATION
    #####################################

  setSize: ( width, height )->
    @winWidth = width
    @win_height = height

  ############################################################
  # 選択画面 (canvas)
  ############################################################
  clearPic: -> @select_pic.clear()

  setPlot: ( width, height, offset )->
    SKEW = 100 # imageの傾き幅
    @PLOT = [
      # 左上
      {
        x1: -offset
        y1: 0
        x2: width / 2 + SKEW / 2 - offset
        y2: 0
        x3: width / 2 - SKEW / 2 - offset
        y3: height / 2 - @TTL_HEIGHT / 2 + 1
        x4: -offset
        y4: height / 2 - @TTL_HEIGHT / 2 + 1
      }
      # 右上
      {
        x1: width / 2 + SKEW / 2 + offset
        y1: 0
        x2: width + offset
        y2: 0
        x3: width + offset
        y3: height / 2 - @TTL_HEIGHT / 2 + 1
        x4: width / 2 - SKEW / 2 + offset
        y4: height / 2 - @TTL_HEIGHT / 2 + 1
      }
      # 右下
      {
        x1: width / 2 + SKEW / 2 + offset
        y1: height / 2 + @TTL_HEIGHT / 2
        x2: width + offset
        y2: height / 2 + @TTL_HEIGHT / 2
        x3: width + offset
        y3: height
        x4: width / 2 - SKEW / 2 + offset
        y4: height
      }
      # 左下
      {
        x1: -offset
        y1: height / 2 + @TTL_HEIGHT / 2
        x2: width / 2 + SKEW / 2 - offset
        y2: height / 2 + @TTL_HEIGHT / 2
        x3: width / 2 - SKEW / 2 - offset
        y3: height
        x4: -offset
        y4: height
      }
    ]

    @select_pic.resetContext width, height
    @select_area.resetContext width, height

  # 100%のマスク状態でイメージを描画 & エリア領域も描画
  drawPic: ( width, height, offset, is_mono )->
    if !offset?
      return if @$select_fixed.css( "display" ) != "block"
      offset = 0

    @setPlot width, height, offset

    _drawImage = ( i )=>
      _original_plot = _mask_plot = @PLOT[ i ]
      if is_mono
        @select_pic.drawImgClip @PIC_IMG_MONO[ i ],
                                _original_plot, _mask_plot
      else
        @select_pic.drawImgClip @PIC_IMG[ i ],
                                _original_plot, _mask_plot
      @select_area.drawAreaClip i + 1, _original_plot if offset == 0

    @select_area.clear()

    for i in [ 0...@PIC_NAME.length ]
      _drawImage i

  # パーセント指定された状態でイメージを描画
  drawMaskedPic: ( id, percent, is_mono )->
    if id == 1 || id == 2 # 右側
      _mask_plot = {
        x1: @PLOT[ id ].x2 - ( @PLOT[ id ].x2 - @PLOT[ id ].x1 ) * percent / 100
        y1: @PLOT[ id ].y1
        x2: @PLOT[ id ].x2
        y2: @PLOT[ id ].y2
        x3: @PLOT[ id ].x3
        y3: @PLOT[ id ].y3
        x4: @PLOT[ id ].x3 - ( @PLOT[ id ].x3 - @PLOT[ id ].x4 ) * percent / 100
        y4: @PLOT[ id ].y4
      }
    else # 左側
      _mask_plot = {
        x1: @PLOT[ id ].x1
        y1: @PLOT[ id ].y1
        x2: @PLOT[ id ].x1 + ( @PLOT[ id ].x2 - @PLOT[ id ].x1 ) * percent / 100
        y2: @PLOT[ id ].y2
        x3: @PLOT[ id ].x4 + ( @PLOT[ id ].x3 - @PLOT[ id ].x4 ) * percent / 100
        y3: @PLOT[ id ].y3
        x4: @PLOT[ id ].x4
        y4: @PLOT[ id ].y4
      }

    _original_plot = @PLOT[ id ]
    
    if is_mono
      @select_pic.drawImgClip @PIC_IMG_MONO[ id ], _original_plot, _mask_plot
    else
      @select_pic.drawImgClip @PIC_IMG[ id ], _original_plot, _mask_plot

  checkArea: ( x, y, is_click )->
    _id = @select_area.getImgData( x, y, 1, 1 ).data[ 0 ]
    if _id != 0
      @$select_container.css cursor: "pointer"
    else
      @$select_container.css cursor: "default"

    @clearPic()
    _length = @PIC_NAME.length
    for i in [ 0..._length ]
      if i == _id - 1
        # ホバーエフェクト
        @select_pic.drawImgClip @PIC_IMG[ i ], @PLOT[ i ], @PLOT[ i ], true
      else
        @select_pic.drawImgClip @PIC_IMG[ i ], @PLOT[ i ], @PLOT[ i ]

    # viewページへ遷移
    if _id != 0 && is_click?
      mouseMoveHandler.clear "MOUSEMOVED"
      @$select_container.css cursor: "default"
      for i in [ 0..._length ]
        if i == _id - 1
          $( ".view_#{ @PIC_NAME[ i ] }" ).show()
          @$select_sub_container.find( ".#{ @PIC_NAME[ i ] }" ).
          addClass "selected"
        else
          $( ".view_#{ @PIC_NAME[ i ] }" ).hide()

      @$select_container.css height: @$view.height()
      @$base.prop scrollTop: @$select_container.get( 0 ).offsetTop
      @dispatch "ENTER_VIEW", this
      _slideOut.call this, => @view_id = _id

getInstance = ->
  if !instance
    instance = new Menu()
  return instance

module.exports = getInstance
