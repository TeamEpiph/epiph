AutoForm.hooks
  editPatientForm:
    onSubmit: (insertDoc, updateDoc, currentDoc) ->
      self = @
      Meteor.call "updatePatients", [Session.get("selectedPatientId")], updateDoc, (error) ->
        if error?
          throwError error
        self.done()
      false

Template.patient.created = ->
  self = @
  @autorun ->
    Session.set 'patientSubscriptionsReady', false
    patient = Patients.findOne Session.get("selectedPatientId")
    if patient?
      self.subscribe("studyCompositesForPatient", patient._id)
      self.subscribe("visitsCompositeForPatient", patient._id, onReady: -> Session.set 'patientSubscriptionsReady', true)

Template.patient.rendered = ->
  @$('[data-toggle=tooltip]').tooltip()

Template.patient.helpers
  designs: ->
    ds = ""
    designs = @studyDesigns().forEach (d) ->
      ds += d.title+', '
    ds.slice(0, -2)

  numVisits: ->
    visits = 0
    @studyDesigns().forEach (d) ->
      visits += d.visits.length if d?
    visits

  template: ->
    selectedDesignVisitId = Session.get 'selectedDesignVisitId'
    if selectedDesignVisitId?
      "patientVisit"
    else
      "patientVisits"

  templateData: ->
    patient: @

  formDoc: ->
    Patients.findOne Session.get("selectedPatientId")

  editPatientSchema: ->
    caseManagers = Meteor.users.find(
      roles: "caseManager"
    ).map (t) ->
      label: getUserDescription(t)
      value: t._id
    designs = StudyDesigns.find(
      studyId: @_id
    ).map (d) ->
      label: d.title
      value: d._id
    langs = isoLangs.map (l) ->
      label: "#{l.name} (#{l.nativeName})"
      value: l.code
    schema =
      primaryLanguage:
        label: 'Primary Language'
        type: String
        optional: true
        autoform:
          options: langs
      secondaryLanguage:
        label: 'Secondary Language'
        type: String
        optional: true
        autoform:
          options: langs
      hrid:
        label: "HRID"
        type: String
        optional: true
        max: 8
    if Roles.userIsInRole(Meteor.userId(), 'admin')
      schema = _.extend schema,
        caseManagerIds:
          label: "Case Managers"
          type: [String]
          optional: true
          autoform:
            type: "select-checkbox"
            options: caseManagers
    new SimpleSchema(schema)

Template.patient.events
  "click .id, click .hrid": (evt) ->
    selectPatientId(@_id, true)

  "click button.delete": (evt) ->
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
                      $('#studiesSelect').selectpicker('deselectAll')
                      Session.set 'selectedDesignVisitId', null
                      Session.set 'selectedPatientId', null
                      Session.set 'selectedStudyIds', null
              return
          else
            throwError error
        else
          swal.close()
          $('#studiesSelect').selectpicker('deselectAll')
          Session.set 'selectedDesignVisitId', null
          Session.set 'selectedPatientId', null
          Session.set 'selectedStudyIds', null
      return
    return false
