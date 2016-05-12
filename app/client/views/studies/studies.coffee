Template.studies.helpers
  studies: ->
    Studies.find()

  studiesRTS: ->
    useFontAwesome: true,
    rowsPerPage: 100,
    showFilter: true,
    fields: [
      { key: 'title', label: "Title" },
      { key: 'creator', label: "Creator", fn: (v,o) -> getUserDescription(o.creator()) },
      { key: "createdAt", label: 'created', sortByValue: true, fn: (v,o)->moment(v).fromNow()},
      { key: 'buttons', label: '', tmpl: Template.editRemoveTableButtons }
    ]


Template.studies.events
  "click #createStudy": (evt) ->
    Meteor.call "createStudy", (error, id) ->
      if error?
        throwError error
        return
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
      closeOnConfirm: false
    }, ->
      Meteor.call "removeStudy", id, null, (error) ->
        if error?
          if error.reason is "answersExistForStudy"
            swal {
              title: 'Attention!'
              text: """The study you are about to remove contains patient data. All patient data will be removed. A log entry will be created. If you really want to proceed please state a reason:"""
              type: 'input'
              showCancelButton: true
              confirmButtonText: 'Yes'
              inputPlaceholder: "Please state a reason."
              closeOnConfirm: false
            }, (confirmedWithReason)->
              if confirmedWithReason is false #cancel
                swal.close()
              else
                if !confirmedWithReason? or confirmedWithReason.length is 0
                  swal.showInputError("You need to state a reason!")
                else
                  Meteor.call "removeStudy", id, confirmedWithReason, (error2) ->
                    if error2?
                      throwError error2
                    else
                      swal.close()
              return false
          else
            throwError error
        else
          swal.close()
      return
    return false
