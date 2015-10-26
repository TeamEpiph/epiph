AutoForm.hooks
  uploadPhysioRecordForm:
    onSubmit: (insertDoc, updateDoc, currentDoc) ->
      metadata =
        visitId: currentDoc._id
        sensor: insertDoc.sensor
        deviceName: insertDoc.deviceName
      self = @
      Meteor.call "updatePhysioRecordMetadata", insertDoc.physioRecordId, metadata, (error) ->
        self.done()
        throwError error if error?
      false

Template.patientVisit.helpers
  #this templateData
  visit: ->
    v = Visits.findOne(@visitId)
    if v?
      v.validatedDoc()
    else v

  #this visit
  showEmpaticaRecorder: ->
    @recordPhysicalData and Meteor.isCordova

  #this visit
  empaticaSessionId: ->
    @_id
    
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
  

Template.questionnaireRow.helpers
  questionnaireCSS: ->
    return "valid" if @questionnaire.answered
    "invalid"

Template.questionnaireRow.events
  #this: {questionnaire, visit, patient}
  "click .answerQuestionnaire": (evt, tmpl) ->
    if !@patient.runningVisitId? or @patient.runningVisitId isnt @visit._id
      alert("This visit must be running to answer it's questionnaires.")
    else
      Modal.show('questionnaireWizzard', @)
    false

  "click .showQuestionnaire": (evt, tmpl) ->
    Modal.show('viewQuestionnaire', @)
    false
