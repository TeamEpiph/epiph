AutoForm.hooks
  uploadPhysioRecordForm:
    onSubmit: (insertDoc, updateDoc, currentDoc) ->
      PhysioRecords.update insertDoc.physioRecordId,
        $set:
          'metadata.visitId': currentDoc._id
          'metadata.sensor': insertDoc.sensor
          'metadata.deviceName': insertDoc.deviceName
      @done()
      false

Template.patientVisit.created = ->
  id = @data.visitId
  @subscribe "physioRecordsForVisit", id
  @subscribe "questionnaires"

Template.patientVisit.helpers
  #this templateData
  visit: ->
    Visits.findOne @visitId

  #this visit
  isRunning: ->
    @startedAt? and !@endedAt?

  canStart: ->
    !@endedAt?

  questionnaires: ->
    qIds = @questionnaireIds or []
    Questionnaires.find
      _id: {$in: qIds}

  #this visit
  showEmpaticaRecorder: ->
    @recordPhysicalData and Meteor.isCordova

  #this visit
  empaticaSessionId: ->
    @_id
    
  #this visit
  physioRecords: ->
    PhysioRecords.find
      'metadata.visitId': @_id

  uploadFormSchema: ->
    schema =
      sensor:
        type: String
        label: "Sensor"
      deviceName:
        type: String
        label: "Device name"
        optional: true
      physioRecordId:
        type: String
        label: " "
        autoform:
          afFieldInput:
            type: 'fileUpload'
            collection: 'PhysioRecords'
            label: 'Choose file'
    new SimpleSchema(schema)
  

Template.patientVisit.events
  "click .startVisit": (evt) ->
    Visits.update @_id,
      $set:
        startedAt: Date.now()
    Patients.update @patientId,
      $set:
        runningVisitId: @_id
  "click .stopVisit": (evt) ->
    Visits.update @_id,
      $set:
        endedAt: Date.now()
    Patients.update @patientId,
      $unset:
        runningVisitId: @_id

Template.answerQuestionnaireRow.events
  #this: {questionnaire, visit, patient}
  "click .answerQuestionnaire": (evt, tmpl) ->
    #Session.set("answeringQuestionnaireId", @_id)
    Modal.show('questionnaireWizzard', @)
    false
