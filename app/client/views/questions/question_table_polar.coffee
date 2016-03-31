#Template.questionTablePolar.rendered = ->
#  max = 0
#  @$('.question-table-polar td:first-child').css('width', '100%')
#  @$('.question-table-polar td:last-child').css('width', '100%')
#  @$('.question-table-polar td:not(:first-child):not(:last-child)').each ->
#    width = $(this).width()+16
#    max = width if width > max
#  @$('.question-table-polar td:not(:first-child):not(:last-child)').css('width', max)
#  @$('.question-table-polar td:first-child').css('width', "")
#  @$('.question-table-polar td:last-child').css('width', "")
