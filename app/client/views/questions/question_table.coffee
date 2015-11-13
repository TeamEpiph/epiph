Template.questionTable.rendered = ->
  max = 0
  @$('.question-table td:first-child').css('width', '100%')
  @$('.question-table td:not(:first-child)').each ->
    width = $(this).width()+16
    max = width if width > max
  @$('.question-table td:not(:first-child)').css('width', max)
  @$('.question-table td:first-child').css('width', "")

Template.questionTable.helpers
  checked: ->
    code = @subquestion.code
    choiceVariable = @choice.variable
    choiceValue = @choice.value
    @answer? and 
    @answer.value? and 
    (_.find @answer.value, (values) ->
      values.code is code and
      (_.find values.checkedChoices, (cc) ->
        cc.value is choiceValue and
        cc.variable is choiceVariable
      )?
    )?

  type: ->
    @question.mode
