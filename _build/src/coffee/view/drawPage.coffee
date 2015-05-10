ticker = require( "../util/ticker" )()
EventDispatcher = require "../util/eventDispatcher"
circleData = require "../model/circleData"
Canvas = require "./canvasManager"
resizeHandler = require( "../controller/resizeHandler" )()
mouseHandler = require( "../controller/mouseHandler" )()
instace = null
  
class DrawCircle extends EventDispatcher
  constructor: -> super()

  exec: ->
    #window.dev = true
    # 右手から左手に回転させ、アニメーションをスタートする
    _DUR = 500

    @$drawPage = $( ".drawPage" )
    @$msg = @$drawPage.find( ".msg" )
    @msg_count = 0

    _$draw_pic = @$drawPage.find( ".draw_pic" )
    _$draw_pic.velocity
      translateX: -$( window ).width() + _$draw_pic.width()
      rotateY: [ 0, -180 ]
    ,
      duration: _DUR
      queue: false

    _$draw_pic.velocity
      scale: [ 0.6, 1 ]
    , _DUR / 2, "linear"
    .velocity
      scale: [ 1, 0.6 ]
    , _DUR / 2, "linear", =>
      _$draw_pic.delay( _DUR * 2 ).velocity opacity: [ 0, 1 ], =>
        _$draw_pic.hide()
        @startAnim()

  startAnim: ->
    #########################
    # DECLARE
    #########################
    
    _$win = $( window )
    _$doc = $( document )

    _$draw_hand = @$drawPage.find( ".draw_hand" )
    _$drawnCircle_container = @$drawPage.find( ".drawnCircle_container" )
    _$complete = @$drawPage.find( ".complete" )
    _$complete_circle = @$drawPage.find( ".complete_circle" )
    _$date = @$drawPage.find( ".date" )
    _$tree_container = @$drawPage.find( ".tree_container" )
    _$tree = @$drawPage.find( ".tree" )
    _$date_num = @$drawPage.find( ".date_num" )
    _$canvas = @$drawPage.find( ".canvas"  )

    _tree_ratio = _$tree_container.height() / _$tree_container.width()
    _tree_origin_width = _$tree_container.width()
    _tree_width_ratio = 1452 / 1020 # 年輪部分に対しての画像全体幅

    if window.record
      _test = []

    _canvas = new Canvas _$canvas

    _mouse_x = null
    _mouse_y = null

    _DRAW_POSITION = # hand.pngにおけるペン先の座標
      x: 497
      y: 156

    _win_width = null
    _win_height = null
    _min_width = null

    _ORIGIN_WIDTH = 1672
    _ORIGIN_HEIGHT = 924

    _DRAW_LINE_WIDTH = 4
    
    _circle_position = {} # 描いた円の座標を記録

    # 描いた円が集まっていくときの座標計算
    _WHOLE_PADDING = 30
    _WHOLE_MARGIN = 10
    _circle_r = null
    _WHOLE_CIRCLE_WIDTH_MAX = 12 # 横幅に入る円の数
    _DRAW_CIRCLE_MAX = 4 # autoDrawさせる数
    _FADE_START_COUNT = 20 # fadeOutを開始するcount数
    _WHOLE_CIRCLE_IMG_MAX = 8
    _circle_count = 0
    _is_completed = false

    _DUR = 500

    #########################
    # PRIVATE
    #########################

    _initDrawData = ->
      _mouse_x = null
      _mouse_y = null

      _circle_position =
        x_min: null
        y_min: null
        x_max: null
        y_max: null

    _ringAnimation = -> # 年輪へのアニメーション
      _circle_length = _$complete_circle.size()
      _whole_width = _$complete.width()
      _start_width = 5
      _width_span = ( _whole_width - _start_width ) / _circle_length

      _$date.addClass "reverse"

      for i in [ 0..._circle_length ]
        _width = _start_width + _width_span * i

        _$complete_circle.eq( i ).velocity
          top: ( _whole_width - _width ) / 2
          left: ( _whole_width - _width ) / 2
          width: _width
          height: _width
        ,
          duration: _DUR * 2
          queue: false

      _wait = if window.dev then _DUR * 2 else _DUR * 6

      setTimeout ->
        _tree_length = _$tree.size()

        _$complete.velocity
          scaleY: [ _tree_ratio, 1 ]
        ,
          duration: _DUR
          queue: false

        setTimeout ->
          _$complete.velocity opacity: [ 0, 1 ], _DUR
          _$tree_container.velocity opacity: [ 1, 0 ], _DUR

          for i in [ 0..._tree_length - 1 ]
            _$tree.eq( _tree_length - 1 - i )
            .delay( _DUR / 2 * i + _DUR ).velocity
              opacity: [ 0, 1 ]
            , _DUR / 2
        , _DUR / 2

        setTimeout (-> _showNextMsg() ), _DUR / 2 * _tree_length + _DUR

      , _wait
 
    _setCompleteCircle = ->
      if _is_completed
        _CIRCLE_WIDTH_MAX = Math.sqrt _$complete_circle.size()
      else
        _CIRCLE_WIDTH_MAX = Math.sqrt _$complete_circle.size() + 1
      _PADDING = 10
      _MARGIN = 5
      _circle_length = _$complete_circle.size()
      _width_min = if _win_width < _win_height then _win_width else _win_height

      _width = ( _width_min - _PADDING * 2 - _MARGIN *
               ( _CIRCLE_WIDTH_MAX - 1 ) ) / _CIRCLE_WIDTH_MAX

      _$complete.css
        width: ( _width + _MARGIN ) * _CIRCLE_WIDTH_MAX
        height: ( _width + _MARGIN ) * _CIRCLE_WIDTH_MAX

      _$tree_container.css
        transform: "scale(#{ ( _width + _MARGIN ) * _CIRCLE_WIDTH_MAX *
                   _tree_width_ratio / _tree_origin_width })"

      _$complete_circle.velocity
        width: _width
        height: _width
      ,
        duration: _DUR * 2
        queue: false

      for i in [ 0..._circle_length ]
        if _is_completed && i != _circle_length - 1
          _$complete_circle.eq( i ).delay( _DUR ).velocity
            opacity: [ 1, 0 ]
          ,
            duration: _DUR * 2
            queue: false

        _$complete_circle.eq( i ).velocity
          top: Math.floor( i / _CIRCLE_WIDTH_MAX ) *
               ( _width + _MARGIN ) - _MARGIN + _PADDING
          left: ( i % _CIRCLE_WIDTH_MAX ) * ( _width + _MARGIN ) -
                _MARGIN + _PADDING
        , _DUR * 2

      _wait = if window.dev then _DUR * 4 else _DUR * 10

      if _is_completed
        _showNextMsg()
        setTimeout ( -> _ringAnimation() ), _wait

    _autoDraw = ( num )->
      cur_circleData = circleData[ num ]
      cur_circleData_length = cur_circleData.length

      ticker.listen "AUTO_WRITE", ( t )->
        _step = Math.floor( t / 10 )

        if _step >= cur_circleData_length
          _step = cur_circleData_length - 1
          is_fin = true

        e = {}
        e.pageX = ( cur_circleData[ _step ].x * ( _min_width / 2 ) ) +
                  _win_width / 2
        e.pageY = cur_circleData[ _step ].y * ( _min_width / 2 ) +
                  _win_height / 2
        mouseHandler.dispatch "MOUSE_DRAGED", this, e

        if is_fin
          ticker.clear "AUTO_WRITE"
          mouseHandler.dispatch "DRAW_END"

    _appendCircleBegin = ->
      _count = 0
      _span = if window.dev then 200 else 600
      _next_t = _span

      ticker.listen "APPEND_CIRCLE_BEGIN", ( t )->
        if t > _next_t
          _append_num = _count + _DRAW_CIRCLE_MAX
          _count += 1
          _span -= 50 if _span >= 50
          _next_t += _span

          _$date_num.text _append_num + 1

          _$drawnCircle = $( "<p>" ).attr class: "drawnCircle"
          _$drawnCircle_container.append _$drawnCircle

          $( "<img>" )
          .attr src: "img/circle_begin/#{ ( _count ) % +
                     _WHOLE_CIRCLE_IMG_MAX + 1 }.png"
          .appendTo _$drawnCircle

          _$drawnCircle.css
            top: Math.floor( _append_num / _WHOLE_CIRCLE_WIDTH_MAX ) *
                 _circle_r + _WHOLE_MARGIN * Math.floor( _append_num /
                 _WHOLE_CIRCLE_WIDTH_MAX ) + _WHOLE_PADDING
            left: ( _append_num % _WHOLE_CIRCLE_WIDTH_MAX ) * _circle_r +
                  _WHOLE_MARGIN * ( _append_num % _WHOLE_CIRCLE_WIDTH_MAX ) +
                  _WHOLE_PADDING
            width: _circle_r
            transform: "scale(0.8)"

          _$drawnCircle.velocity scale: [ 1, 0.6 ], _DUR / 2

          if _count == 20 # fadeout開始
            _$drawnCircle_container.velocity opacity: [ 0, 1 ], _DUR * 8, ->
              ticker.clear "APPEND_CIRCLE_BEGIN"
              _$drawnCircle_container.empty()
              _skipCount()

    _appendCircleFin = ( from )=>
      _count = 0
      _span = 50
      _next_t = _span
      _MAX_DATE = 3652

      _showNextMsg() if !window.dev

      ticker.listen "APPEND_CIRCLE_FIN", ( t )=>
        if t > _next_t
          _append_num = _count
          _count += 1
          _span += 5 if !window.dev
          _next_t += _span

          _$date_num.text _append_num + from

          _$drawnCircle = $( "<p>" ).attr class: "drawnCircle"
          _$drawnCircle_container.append _$drawnCircle

          $( "<img>" )
          .attr src: "img/circle_fin/#{ ( _count ) %
                     _WHOLE_CIRCLE_IMG_MAX + 1 }.png"
          .appendTo _$drawnCircle

          _$drawnCircle.css
            top: Math.floor( _append_num / _WHOLE_CIRCLE_WIDTH_MAX ) *
                 _circle_r + _WHOLE_MARGIN * Math.floor( _append_num /
                 _WHOLE_CIRCLE_WIDTH_MAX ) + _WHOLE_PADDING
            left: ( _append_num % _WHOLE_CIRCLE_WIDTH_MAX ) * _circle_r +
                  _WHOLE_MARGIN * ( _append_num % _WHOLE_CIRCLE_WIDTH_MAX ) +
                  _WHOLE_PADDING
            width: _circle_r
            transform: "scale(0.8)"

          _$drawnCircle.velocity
            opacity: [ 1, 0 ]
            scale: [ 1, 0.8 ]
          ,_DUR / 2

          if _append_num == 0 # fadein開始
            _$drawnCircle_container.delay( 300 )
            .velocity opacity: [ 1, 0 ], _DUR * 8

          if _append_num + from == _MAX_DATE
            if !window.dev
              _wait = _DUR * 4
            else
              _wait = _DUR * 2

            ticker.clear "APPEND_CIRCLE_FIN"
            setTimeout =>
              _$drawnCircle_each =
                _$drawnCircle_container.find( ".drawnCircle" )
              _$drawnCircle_length = _$drawnCircle_each.size()
              _$drawnCircle_last =
                _$drawnCircle_each.eq( _$drawnCircle_length - 1 )

              for i in [ 0..._$drawnCircle_length - 1 ]
                _$drawnCircle_each.eq( i ).velocity opacity: [ 0, 1 ], _DUR

              _$drawnCircle_last.velocity
                top: _win_height * 0.1
                left: _win_width * 0.5 - _win_height * 0.4
                width: _win_height * 0.8
                height: _win_height * 0.8
              , _DUR, -> _showNextMsg()

              _wait = if window.dev then _DUR * 4 else _DUR * 12

              setTimeout =>
                _origin_top = _$drawnCircle_last.get( 0 ).offsetTop
                _origin_left = _$drawnCircle_last.get( 0 ).offsetLeft

                _$drawnCircle_last
                .attr class: "complete_circle"
                .appendTo _$complete

                _$complete_circle = @$drawPage.find( ".complete_circle" )
                _$complete_circle.eq( _$complete_circle.size() - 1 ).velocity
                  top: _origin_top - _$complete.get( 0 ).offsetTop
                  left: _origin_left - _$complete.get( 0 ).offsetLeft
                , 10

                _is_completed = true
                _setCompleteCircle()
              , _wait
            , _wait

    _skipCount = ->
      _from = parseInt _$date_num.text()
      _MAX_DATE = 3605
      _FIRST_YEAR = 365
      _FIVE_YEAR = 365 * 5

      _shown_first_year = false
      _shown_five_year = false

      ticker.listen "SKIP_COUNT", ( t )->
        if window.dev
          _date = Math.floor _from + t * 100
        else
          _date = Math.floor _from + t / 2
        _$date_num.text _date

        _date_num = parseInt _date

        if !_shown_first_year && _date_num > _FIRST_YEAR
          console.log "first"
          _shown_first_year = true
          _showNextMsg() if !window.dev
        else if !_shown_five_year && _date_num > _FIVE_YEAR
          console.log "five"
          _shown_five_year = true
          _showNextMsg() if !window.dev

        if _date >= _MAX_DATE
          ticker.clear "SKIP_COUNT"
          _appendCircleFin _MAX_DATE

    _showNextMsg = =>
      console.log @msg_count
      _count = @msg_count
      @msg_count += 1
      @$msg.eq( _count ).velocity
        opacity: [ 1, 0 ]
      , _DUR * 3, =>
        @$msg.eq( _count ).delay( _DUR * 3 ).velocity
          opacity: [ 0, 1 ]
        , _DUR * 3, =>
          @dispatch "DRAW_FIN" if @msg_count == @$msg.size()

    #########################
    # EVENT LISTENER
    #########################

    ticker.listen "MOVE_HAND", ->
      if _mouse_x != null
        _$draw_hand.css
          opacity: 1
          top: _mouse_y - _DRAW_POSITION.y
          left: _mouse_x - _DRAW_POSITION.x

    resizeHandler.listen "RESIZED", ->
      _win_width = _$win.width()
      _win_height = _$win.height()
      _min_width = if _win_width < _win_height then _win_width else _win_height

      _canvas.resetContext _win_width, _win_height
      _circle_r = ( _$win.width() - _WHOLE_PADDING * 2 - _WHOLE_MARGIN *
                 ( _WHOLE_CIRCLE_WIDTH_MAX - 1 ) ) / _WHOLE_CIRCLE_WIDTH_MAX

      $( ".drawnCircle" ).css width: _circle_r
      _setCompleteCircle()

    mouseHandler.listen "MOUSE_MOVED", ( e )->
      _mouse_x = e.pageX
      _mouse_y = e.pageY

    mouseHandler.listen "MOUSE_DRAGED", ( e )->
      if _mouse_x != null
        _canvas.drawLine e.pageX, e.pageY, _mouse_x, _mouse_y

      if window.record
        _test.push
          x: ( e.pageX - _win_width / 2 ) / ( _min_width / 2 )
          y: ( e.pageY - _win_height / 2 ) / ( _min_width / 2 )

        if Math.abs( ( e.pageX - _win_width / 2 ) / ( _min_width / 2 ) ) > 1 ||
           Math.abs( ( e.pageY - _win_height / 2 ) / ( _min_width / 2 ) ) > 1
          alert "描画範囲を超えました"

      _mouse_x = e.pageX
      _mouse_y = e.pageY # 直前の位置を記憶する役割を果たす

      if _circle_position.x_min == null # 初めに全ての座標をセット
        _circle_position.x_min = _mouse_x
        _circle_position.y_min = _mouse_y
        _circle_position.x_max = _mouse_x
        _circle_position.y_max = _mouse_y

      _circle_position.x_min = _mouse_x if _mouse_x < _circle_position.x_min
      _circle_position.y_min = _mouse_y if _mouse_y < _circle_position.y_min
      _circle_position.x_max = _mouse_x if _mouse_x > _circle_position.x_max
      _circle_position.y_max = _mouse_y if _mouse_y > _circle_position.y_max

    mouseHandler.listen "DRAW_END", ->
      if window.record
        _json = JSON.stringify _test
        _blob = new Blob [ _json ], type: "application/json"
        _url  = URL.createObjectURL _blob

        $( "<a>" ).attr
          download: "test.json"
          href: _url
          textContent: "Download backup.json"
        .appendTo "body"

      _$drawnCircle = $( "<p>" ).attr class: "drawnCircle"
      _$drawnCircle_container.append _$drawnCircle
      
      _circle_img = new Image()
      _circle_img.src = _canvas.getImg()

      _circle = new Canvas $( "<canvas>" )
      _circle.resetContext(
        _circle_position.x_max - _circle_position.x_min + _DRAW_LINE_WIDTH,
        _circle_position.y_max - _circle_position.y_min + _DRAW_LINE_WIDTH
      )
      _circle.drawImg(
        _circle_img,
        -_circle_position.x_min + _DRAW_LINE_WIDTH / 2,
        -_circle_position.y_min + _DRAW_LINE_WIDTH / 2
      )

      # 描いたcanvasデータをimgタグに置き換え
      _canvas.clear()
      $( "<img>" ).attr( src: _circle.getImg() ).appendTo _$drawnCircle
      _$drawnCircle.css
        top: _circle_position.y_min - _DRAW_LINE_WIDTH / 2
        left: _circle_position.x_min - _DRAW_LINE_WIDTH / 2

      _wait = if _circle_count == 0 then _DUR * 12 else _DUR * 2
      _wait = _DUR / 2 if window.dev

      _$drawnCircle.delay( _wait ).velocity
        top: Math.floor( _circle_count / _WHOLE_CIRCLE_WIDTH_MAX ) * _circle_r +
             _WHOLE_MARGIN * Math.floor( _circle_count /
             _WHOLE_CIRCLE_WIDTH_MAX ) + _WHOLE_PADDING
             
        left: ( _circle_count % _WHOLE_CIRCLE_WIDTH_MAX ) * _circle_r +
              _WHOLE_MARGIN * ( _circle_count %
              _WHOLE_CIRCLE_WIDTH_MAX ) + _WHOLE_PADDING
        width: _circle_r
      , _DUR

      _circle_count += 1
      _circle_img = null
      _circle = null

      _$date_num.text _circle_count
      _$date.show().velocity
        translateX: [ 0, 20 ]
        opacity: [ 1, 0 ]
      , _DUR

      if _circle_count >= _DRAW_CIRCLE_MAX
        _wait = if window.dev then _DUR / 2 else _DUR * 4
        setTimeout ( -> _appendCircleBegin() ), _wait
        return

      _wait = if window.dev then _DUR / 4 else _DUR * 3
      if _circle_count == 1
        _$draw_hand.velocity opacity: [ 0, 1 ], _DUR
        mouseHandler.off()
        ticker.clear "MOVE_HAND"
        _wait = if window.dev then _DUR / 2 else _DUR * 16
        if !window.dev
          setTimeout (-> _showNextMsg() ), _DUR * 3
      else if _circle_count == 2
        if !window.dev
          setTimeout (-> _showNextMsg() ), _DUR * 3

      setTimeout ->
        _initDrawData()
        _autoDraw _circle_count
        _$date.velocity opacity: [ 0, 1 ], _DUR
      , _wait

    #########################
    # INIT
    #########################

    resizeHandler.exec()
    if window.preview
      _autoDraw 0
    else
      mouseHandler.exec()

    _canvas.setLineWidth _DRAW_LINE_WIDTH

    resizeHandler.dispatch "RESIZED"
    _initDrawData()

getInstance = ->
  if !instance
    instance = new DrawCircle()
  return instance

module.exports = getInstance
