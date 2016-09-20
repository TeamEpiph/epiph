waitingForPatientId = null
waitingForDesignVisitId = null
Template.patientVisit.rendered = ->
  @autorun ->
    if !Session.get 'patientSubscriptionsReady'
      return 
    data = Template.currentData()
    patientId = data.patient._id
    designVisitId = Session.get 'selectedDesignVisitId'
    return if not designVisitId?
    v = Visits.findOne
      designVisitId: designVisitId
    if not v? and (waitingForPatientId isnt patientId or waitingForDesignVisitId isnt designVisitId)
      #console.log 'initVisit'
      waitingForPatientId = patientId
      waitingForDesignVisitId = designVisitId
      Meteor.call "initVisit", designVisitId, patientId, (error, _id) ->
        throwError error if error?


Template.patientVisit.helpers
  designTitle: ->
    sdId = Session.get 'selectedPatientStudyDesignId'
    StudyDesigns.findOne(sdId).title

  #this templateData
  visit: ->
    designVisitId = Session.get 'selectedDesignVisitId'
    v = Visits.findOne
      designVisitId: designVisitId
    v.validatedDoc() if v?

  #with questionnaire=this visit=.. patient=../../patient
  questionnaireCSS: ->
    return "valid" if @questionnaire.answered
    "invalid"


Template.patientVisit.events
  #this visit
  "click .designTitle": (evt) ->
    selectPatientId(@patientId, true) 

  #with questionnaire=this visit=.. patient=../../patient
  "click .answerQuestionnaire": (evt, tmpl) ->
    data =
      questionnaire: @questionnaire
      visit: @visit
      patient: @patient
      readonly: false
    __showQuestionnaireWizzard data
    false

  #this: {questionnaire, visit, patient}
  "click .showQuestionnaire": (evt, tmpl) ->
    data =
      questionnaire: @questionnaire
      visit: @visit
      patient: @patient
      readonly: true
    __showQuestionnaireWizzard data
    false
