Template.questionTableInput.rendered = ->
  #we calculate checked here because we need to set it to defaultChecked of the element and as attribute (a helper would come to late)
  code = @data.subquestion.code
  choiceVariable = @data.choice.variable
  choiceValue = @data.choice.value
  @data.answer? and 
  @data.answer.value? and 
  checked = (_.find @data.answer.value, (values) ->
    values.code is code and
    (_.find values.checkedChoices, (cc) ->
      cc.value is choiceValue and
      cc.variable is choiceVariable
    )?
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
