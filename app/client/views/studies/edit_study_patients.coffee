AutoForm.hooks
  editSessionPatientsForm:
    onSubmit: (insertDoc, updateDoc, currentDoc) ->
      self = @
      ids = Session.get 'editingPatientIds'
      if ids.length > 1
        updateDoc = _.pickDeep updateDoc, "$set.therapistId", "$set.studyDesignId"
      Meteor.call "updatePatients", Session.get('editingPatientIds'), updateDoc, (error) ->
        self.done()
        throwError error if error?
      false

Template.editStudyPatients.rendered = ->
  Session.set('editingPatientIds', null)

Template.editStudyPatients.helpers
  patients: ->
    Patients.find
      studyId: @_id

  patientsRTS: ->
    useFontAwesome: true,
    rowsPerPage: 100,
    showFilter: true,
    fields: [
      { key: 'id', label: "", sortable: false, fn: (v, o) -> new Spacebars.SafeString("<input type='checkbox' data-id=#{o._id} />") },
      { key: 'id', label: "ID" },
      { key: 'hrid', label: "HRID" },
      { key: 'therapistId', label: "Design", fn: (v,o) -> design = o.studyDesign(); return design.title if design? },
      { key: 'therapistId', label: "Therapist", fn: (v,o) -> getUserDescription(o.therapist()) },
      { key: 'isExcluded', label: "excluded", tmpl: Template.studyPatientsTableExcluded }
      { key: "createdAt", label: 'created', sortByValue: true, sortOrder: 0, sortDirection: 'descending', fn: (v,o)->fullDate(v) },
      { key: 'buttons', label: '', tmpl: Template.studyPatientsTableButtons }
    ]


  editingPanelTitle: ->
    ids = Session.get('editingPatientIds')
    return "Patient editor" if !ids? or ids.length is 0
    if ids.length > 1
      "edit #{ids.length} patients"
    else
      p = Patients.findOne _id: ids[0]
      "edit patient: #{p.id}"

  numPatientsEditing: ->
    ids = Session.get('editingPatientIds')
    return ids.length if ids?
    false

  formDoc: ->
    ids = Session.get('editingPatientIds')
    if !ids? or ids.length is 0 or ids.length > 1
      null
    else
      Patients.findOne _id: ids[0]
    
  editSessionPatientsSchema: ->
    therapists = Meteor.users.find(
      roles: "therapist"
    ).map (t) ->
      label: getUserDescription(t)
      value: t._id
    designs = StudyDesigns.find(
      studyId: @_id
    ).map (d) ->
      label: d.title
      value: d._id
    schema =
      therapistId:
        label: "Therapist"
        type: String
        optional: true
        autoform:
          type: "select"
          options: therapists
      studyDesignId:
        label: "Design"
        type: String
        optional: true
        autoform:
          type: "select"
          options: designs
    ids = Session.get('editingPatientIds')
    if ids? and ids.length is 1
      schema = _.extend schema, 
        hrid:
          label: "HRID"
          type: String
          optional: true
          max: 8
    new SimpleSchema(schema)

Template.editStudyPatients.events
  "click #createPatient": (evt) ->
    Meteor.call "createPatient", @_id, (error, patientId) ->
      if error?
        throwError error
      else
        editingPatientIds = Session.get("editingPatientIds") or []
        editingPatientIds.push patientId
        $("input[data-id=#{patientId}]").prop 'checked', true
        Session.set "editingPatientIds", _.uniq editingPatientIds
    return


  "click .reactive-table tr": (evt) ->
    return if !@_id #header
    editingPatientIds = Session.get("editingPatientIds") or []
    checkbox = $(evt.target).parent().find('input')
    if event.target.type is "checkbox"
      if (index = editingPatientIds.indexOf(@_id)) > -1
        editingPatientIds.splice(index, 1)
        checkbox.prop('checked', false)
      else
        editingPatientIds.push @_id
        checkbox.prop('checked', true)
      Session.set "editingPatientIds", _.uniq editingPatientIds
    else #click on row
      $('.editStudyPatients table').find('input').prop 'checked', false
      checkbox.prop('checked', true)
      Session.set "editingPatientIds", [@_id]
    return

    
  "click button.show": (evt) ->
    selectPatientId(@_id)
    Router.go "patients"

  "click button.remove": (evt) ->
    patientId = @_id
    swal {
      title: 'Are you sure?'
      text: 'Do you really want to delete this patient? A log entry will be created.'
      type: 'warning'
      showCancelButton: true
      confirmButtonText: 'Yes'
      closeOnConfirm: false
    }, ->
      Meteor.call "removePatient", patientId, (error) ->
        if error?
          if error.reason is "patientHasData"
            swal {
              title: 'Attention!'
              text: """The patient you are about to remove has data entries. Please consider using the exclude checkbox instead. If you really want to proceed removing the patient please state a reason. A log entry will be created."""
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
                  Meteor.call "removePatient", patientId, confirmedWithReason, (error2) ->
                    if error2?
                      throwError error2
                    else
                      swal.close()
              return
          else
            throwError error
        else
          swal.close()
      return
    return false

  "click button.exclude": (evt) ->
    patientId = @_id
    swal {
      title: 'Exclude patient'
      text: 'If you really want to exclude this patient, type a reason and choose Yes.'
      type: 'input'
      showCancelButton: true
      confirmButtonText: 'Yes'
      inputPlaceholder: "Reason for exclusion."
      closeOnConfirm: false
    }, (reason) ->
      if reason is false #cancel
        swal.close()
        return
      if !reason? or reason.length is 0
        swal.showInputError("You need to state a reason!")
        return false
      Meteor.call "excludePatient", patientId, reason, (error) ->
        if error?
          throwError error
        else
          swal("the patient has been excluded.")
      return true
    return false

  "click button.include": (evt) ->
    patientId = @_id
    swal {
      title: 'Include patient'
      text: 'If you really want to include this patient again, type a reason and choose Yes.'
      type: 'input'
      showCancelButton: true
      confirmButtonText: 'Yes'
      inputPlaceholder: "Reason for inclusion."
      closeOnConfirm: false
    }, (reason) ->
      if reason is false #cancel
        swal.close()
        return
      if !reason? or reason.length is 0
        swal.showInputError("You need to state a reason!")
        return false
      Meteor.call "includePatient", patientId, reason, (error) ->
        if error?
          throwError error 
        else
          swal("the patient has been included.")
      return true
    return false

Template.studyPatientsTableExcluded.rendered = ->
  tmpl = @
  @autorun ->
    Template.currentData()
    tmpl.$('[data-toggle=tooltip]').tooltip()
  return

Template.studyPatientsTableExcluded.helpers
  lastExcludeInclude: ->
    l = @excludesIncludes.length
    if l > 0
      @excludesIncludes[l-1]
    else
      null
