Template.questionTable.rendered = ->
  tmpl = @
  Meteor.setTimeout ->
    max = 0
    tmpl.$('.question-table td:first-child').css('width', '60%')
    tmpl.$('.question-table td:not(:first-child)').each ->
      width = $(this).width()+16
      max = width if width > max
    tmpl.$('.question-table td:not(:first-child)').css('width', max)
    tmpl.$('.question-table td:first-child').css('width', "")
  , 200
