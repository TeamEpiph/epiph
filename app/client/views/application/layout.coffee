ResizeTimeout = null
@adjustRowsHeight = ->
  Meteor.clearTimeout(ResizeTimeout) if ResizeTimeout?
  ResizeTimeout = Meteor.setTimeout(doAdjustRowsHeight, 300)
  doAdjustRowsHeight()
  return

doAdjustRowsHeight = ->
  wHeight = $(window).height()
  $(".row-fill").each (index, element) ->
    ele = $(element)
    offset = ele.offset()
    #height = wHeight-offset.top
    height = wHeight;
    height = 350 if height <= 350
    $(element).height(height)
  $(".row-max-half").each (index, element) ->
    ele = $(element)
    offset = ele.offset()
    maxHeight = (wHeight-offset.top)/2.0
    $(element).css('max-height', maxHeight)

Template.layout.rendered = ->
  adjustRowsHeight()
  $(window).resize(adjustRowsHeight)
#Template.layout.destroyed = ->
#  $(window).off("resize", adjustRowsHeight)
