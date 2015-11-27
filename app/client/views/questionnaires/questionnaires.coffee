Template.questionnaires.helpers
  questionnaires: ->
    Questionnaires.find()

  questionnairesRTS: ->
    useFontAwesome: true,
    rowsPerPage: 100,
    showFilter: true,
    fields: [
      { key: 'title', label: "Title" },
      { key: 'numQuestions', label: "num. questions", fn:(v,o)-> Questions.find( questionnaireId: o._id ).count() },
      { key: 'creator', label: "Creator", fn: (v,o) -> c = o.creator(); return c.profile.name if c? },
      { key: "createdAt", label: 'created', sortByValue: true, fn: (v,o)->moment(v).fromNow()},
      { key: 'buttons', label: '', tmpl: Template.editRemoveTableButtons }
    ]


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


