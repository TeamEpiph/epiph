Template.questionTableInput.rendered = ->
  #we calculate checked here because we need to set it to defaultChecked of the element and as attribute (a helper would come to late)
  mode = @data.question.mode
  code = @data.subquestion.code
  if mode is 'checkbox'
    choiceVariable = @data.choice.variable
  else #if mode is 'radio'
    choiceValue = @data.choice.value
  @data.answer? and
  @data.answer.value? and
  checked = (_.find @data.answer.value, (subanswer) ->
    subanswer.code is code and
      ((mode is "checkbox" and
      subanswer.value.indexOf(choiceVariable) > -1 ) or
      (mode is "radio" and 
      subanswer.value is choiceValue) )
  )?
  if checked
    e = @$('input')
    e.prop('checked', checked)
    e[0].defaultChecked = checked
  return

Template.questionTableInput.helpers
  disabled: ->
    if @readonly
      "disabled"
    else
      ""
