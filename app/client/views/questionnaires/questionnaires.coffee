Template.questionnaires.helpers
  questionnaires: ->
    Questionnaires.find()

  questionnairesRTS: ->
    useFontAwesome: true,
    rowsPerPage: 100,
    showFilter: true,
    fields: [
      { key: 'title', label: "Title", sortByValue: true, fn: (v,o)->if o.id then "#{o.title} (#{o.id})" else o.title },
      { key: 'numQuestions', label: "num. questions" },
      { key: 'numPages', label: "num. pages" },
      { key: 'creator', label: "Creator", fn: (v,o) -> getUserDescription(o.creator()) },
      { key: "createdAt", label: 'created', sortByValue: true, fn: (v,o)->fullDate(v)},
      { key: 'buttons', label: '', tmpl: Template.questionnairesTableButtons }
    ]


Template.questionnaires.events
  "click #createQuestionnaire": (evt) ->
    Meteor.call "createQuestionnaire", (error, id) ->
      throwError error if error?
      Router.go('editQuestionnaire', {_id: id})
      return

  "click button.edit": (evt) ->
    evt.stopPropagation()
    Router.go('editQuestionnaire', {_id: @_id})
    return false

  "click button.copy": (evt) ->
    evt.stopPropagation()
    Meteor.call "copyQuestionnaire", @_id, (error) ->
      throwError error if error
    return false

  "click button.remove": (evt) ->
    id = @_id
    swal {
      title: 'Are you sure?'
      text: 'Do you really want to delete this questionnaire?'
      type: 'warning'
      showCancelButton: true
      confirmButtonText: 'Yes'
      closeOnConfirm: false
    }, ->
      Meteor.call "removeQuestionnaire", id, (error) ->
        if error?
          throwError error
        else
          swal.close()
      return true
    return false
