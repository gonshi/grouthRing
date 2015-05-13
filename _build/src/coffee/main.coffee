###!
  * Main Function
###

if window._DEBUG
  if Object.freeze?
    window.DEBUG = Object.freeze window._DEBUG
  else
    window.DEBUG = state: true
else
  if Object.freeze?
    window.DEBUG = Object.freeze state: false
  else
    window.DEBUG = state: false

require "../js/velocity.min.js"
drawPage = require( "./view/drawPage" )()

$ ->
  #####################
  # DECLARE
  #####################
  
  $wrapper = $( ".wrapper" )
  $page = $( ".page" )
  $next = $( ".next" )
  ENTER_KEY = 13
  SPACE_KEY = 32
  PAGE_MAX = $page.size() - 1
  cur_page = 0

  DUR = 500

  #####################
  # PRIVATE
  #####################

  _setNextBtn = ->
    $next.velocity opacity: [ 1, 0 ], DUR

    $( window ).on "keydown", ( e )->
      if e.keyCode == ENTER_KEY &&
         cur_page < PAGE_MAX

        $( window ).off "keydown"

        $next.velocity "stop"
        .velocity opacity: [ 0, 1 ], DUR / 2

        cur_page += 1

        if cur_page == 7
          _dur = 0
          setTimeout ( -> drawPage.exec() ), DUR * 2
        else
          _dur = DUR / 2

        $wrapper.velocity( "stop" )
        .velocity translateY: "#{ -100 * cur_page }%", _dur

        if cur_page != 7 && cur_page < PAGE_MAX
          setTimeout ( -> _setNextBtn() ), 1
      ###
      else if e.keyCode == SPACE_KEY &&
        cur_page > 0
        cur_page -= 1
      ###

  #####################
  # EVENT LISTENER
  #####################

  drawPage.listen "DRAW_FIN", -> _setNextBtn()

  #####################
  # INIT
  #####################

  window.dev = false
  window.record = false
  window.preview = false

  # test
  #drawPage.exec()

  setTimeout ( -> _setNextBtn() ), 1

  $page.each -> # 行数に合わせて高さを調整
    $( this ).find( ".msg" ).each ->
      $( this ).css
        height: "#{ ( $( this ).find( "br" ).size() + 1 ) * 1.5 }em"
