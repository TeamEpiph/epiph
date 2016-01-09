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

  #with questionnaire=this visit=.. patient=../../patient
  questionnaireCSS: ->
    return "valid" if @questionnaire.answered
    "invalid"

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
  

Template.patientVisit.events
  #with questionnaire=this visit=.. patient=../../patient
  "click .answerQuestionnaire": (evt, tmpl) ->
    Modal.show('questionnaireWizzard', @)
    false

  #this: {questionnaire, visit, patient}
  "click .showQuestionnaire": (evt, tmpl) ->
    Modal.show('viewQuestionnaire', @)
    false

  "click .download": (evt) ->
    window.open @url(), '_blank'

  "click .remove": (evt) ->
    evt.preventDefault()
    if confirm "Are you sure?"
      Meteor.call "removePhysioRecord", @_id, (error) ->
        throwError error if error?
