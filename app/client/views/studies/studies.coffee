Template.studies.helpers
  studies: ->
    Studies.find()

  studiesRTS: ->
    useFontAwesome: true,
    rowsPerPage: 100,
    showFilter: true,
    fields: [
      { key: 'title', label: "Title" },
      { key: 'key', label: "Key", sort: 'descending'},
      { key: 'creator', label: "Creator", fn: (v,o) -> c = o.creator(); return c.profile.name if c? },
      { key: "createdAt", label: 'created', sortByValue: true, fn: (v,o)->moment(v).fromNow()},
      { key: 'buttons', label: '', tmpl: Template.editRemoveTableButtons }
    ]


Template.studies.events
  "click #createStudy": (evt) ->
    Meteor.call "createStudy", (error, id) ->
      throwError error if error?
      Router.go('editStudy', {_id: id})
      return

  "click button.edit": (evt) ->
    evt.stopPropagation()
    Router.go('editStudy', {_id: @_id})
    return false

  "click button.remove": (evt) ->
    id = @_id
    swal {
      title: 'Are you sure?'
      text: 'Do you really want to delete this study?'
      type: 'warning'
      showCancelButton: true
      confirmButtonText: 'Yes'
    }, ->
      Meteor.call "removeStudy", id, (error) ->
        throwError error if error
      return
    return false
