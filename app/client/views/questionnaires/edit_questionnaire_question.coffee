Template.editQuestionnaireQuestion.helpers
  #this question, options
  questionCSS: ->
    if @question._id is Session.get("selectedQuestionId")
      "selectedQuestion"
    else
      ""
