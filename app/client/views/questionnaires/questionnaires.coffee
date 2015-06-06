Template.questionnaires.helpers
  questionnaires: ->
    Questionnaires.find()

Template.questionnaires.events
  "click #createQuestionnaire": (evt) ->
    Meteor.call "createQuestionnaire", (error, id) ->
      throwError error if error?
      return

   "click button.edit": (evt) ->
     evt.stopPropagation()
     Router.go('editQuestionnaire', {_id: @_id})
     return false

   "click button.remove": (evt) ->
     if confirm("Delete Questionnaire?")
       Meteor.call "removeQuestionnaire", @_id, (error) ->
         throwError error.reason if error
     return false


