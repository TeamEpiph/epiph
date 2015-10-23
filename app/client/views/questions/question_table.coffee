Template.questionTable.helpers
  checked: ->
    subquestionIndex = @subquestionIndex
    choiceValue = @choice.value
    @answer? and 
    @answer.value? and 
    (_.find @answer.value, (values) ->
      values.subquestionIndex is subquestionIndex and
      values.choiceValues.indexOf(choiceValue) > -1
    )?
