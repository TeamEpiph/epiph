Template.questionTable.rendered = ->
  max = 0
  @$('.question-table td:first-child').css('width', '100%')
  @$('.question-table td:not(:first-child)').each ->
    width = $(this).width()+16
    max = width if width > max
  @$('.question-table td:not(:first-child)').css('width', max)
  @$('.question-table td:first-child').css('width', "")
