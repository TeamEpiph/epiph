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

  #this visit
  canStart: ->
    patient = Template.parentData().patient
    !@endedAt? and !patient.runningVisitId?

  #this visit
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

  #this visit
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
    Meteor.call "startVisit", @_id, (error) ->
      throwError error if error?
      return
  "click .stopVisit": (evt) ->
    Meteor.call "stopVisit", @_id, (error) ->
      throwError error if error?
      return

Template.answerQuestionnaireRow.events
  #this: {questionnaire, visit, patient}
  "click .answerQuestionnaire": (evt, tmpl) ->
    Session.set("answeringQuestionnaireId", @_id)
    if !@patient.runningVisitId? or @patient.runningVisitId isnt @visit._id
      alert("This visit must be running to answer it's questionnaires.")
    else
      Modal.show('questionnaireWizzard', @)
    false
