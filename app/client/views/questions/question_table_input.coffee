Template.questionTableInput.rendered = ->
  #we calculate checked here because we need to set it to defaultChecked of the element and as attribute (a helper would come to late)
  selectionMode = @data.question.selectionMode
  code = @data.subquestion.code
  if selectionMode is 'multi'
    choiceVariable = @data.choice.variable
  else #if selectionMode is 'single'
    choiceValue = @data.choice.value
  @data.answer? and
  @data.answer.value? and
  checked = (_.find @data.answer.value, (subanswer) ->
    subanswer.code is code and
      ((selectionMode is "multi" and
      subanswer.value.indexOf(choiceVariable) > -1 ) or
      (selectionMode is "single" and 
      subanswer.value is choiceValue) )
  )?
  if checked
    e = @$('input')
    e.prop('checked', checked)
    e[0].defaultChecked = checked
  return

Template.questionTableInput.helpers
  type: ->
    if @question.selectionMode is "multi"
      "checkbox"
    else #if @question.selectionMode is "single"
      "radio"

  disabled: ->
    if @readonly
      "disabled"
    else
      ""
