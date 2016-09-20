Template.patientVisits.destroyed = ->
  $('.x-editable-meteorized').off 'shown', __editableDateSanitizer

Template.patientVisits.rendered = ->
  #manage selectedPatientStudyDesignId
  @autorun ->
    sSDId = Session.get('selectedPatientStudyDesignId')
    patient = Template.currentData().patient
    if !patient? or !patient.studyDesignIds? or patient.studyDesignIds.length is 0
      return
    if !sSDId? or patient.studyDesignIds.indexOf(sSDId) < 0
      studyDesigns = patient.studyDesigns().fetch()
      if studyDesigns? and studyDesigns.length > 0
        sdId = studyDesigns[0]._id
      if sdId?
        Session.set 'selectedPatientStudyDesignId', sdId
      else
        Session.set 'selectedPatientStudyDesignId', null
    return

refreshEditableDateSanitizer = ->
  Meteor.setTimeout ->
    $('.x-editable-meteorized').on 'shown', __editableDateSanitizer
  , 100

Template.patientVisits.helpers
  designs: ->
    @patient.studyDesigns()

  designTabClasses: ->
    if @_id is Session.get('selectedPatientStudyDesignId')
      "active"
    else
      ""

  visits: ->
    patient = @patient
    studyDesigns = patient.studyDesigns().fetch()
    selectedPatientStudyDesignId = Session.get 'selectedPatientStudyDesignId'
    if !studyDesigns? or studyDesigns.length is 0 or !selectedPatientStudyDesignId?
      return null
    visits = __getScheduledVisitsForPatientId(patient._id, selectedPatientStudyDesignId)
    now = moment()
    visits.forEach (v) ->
      date = null
      if v.date?
        date = moment(v.date)
      else if v.dateScheduled?
        date = moment(v.dateScheduled)
      if !date?
        v.dateCSS = "no-date"
      else 
        if date.year() is now.year() and date.dayOfYear() is now.dayOfYear()
          v.dateCSS = "due"
        else if date.isBefore(now)
          v.dateCSS = "over-due"
        else
          v.dateCSS = "future"
    visits

  visitDateEO: ->
    refreshEditableDateSanitizer()
    visit = @visit
    patient = @patient
    date = visit.date or visit.dateScheduled or null 
    dateString = null
    if date?
      dateString = fullDate(date)
    value: dateString
    emptytext: "no date set"
    success: (response, newVal) ->
      if newVal is "-"
        date = null
      else
        date = sanitizeDate(newVal)
        if !date?
          return "invalid date"
      if !visit.designVisitId #we have a template
        Meteor.call "initVisit", visit._id, patient._id, (error, visitId) ->
          throwError error if error?
          Meteor.call "changeVisitDate", visitId, date, (error) ->
            throwError error if error?
      else
        Meteor.call "changeVisitDate", visit._id, date, (error) ->
          throwError error if error?
      return

  #this questionnaire visit patient
  questionnaireCSS: ->
    return "valid" if @questionnaire.answered
    "invalid"
  
  #this questionnaire visit patient
  physioRecordsCSS: ->
    return "valid" if @visit.physioValid
    "invalid"


Template.patientVisits.events
  "click .switchDesign": (evt) ->
    Session.set 'selectedPatientStudyDesignId', @_id

  #with questionnaire visit= patient
  "click .showQuestionnaire": (evt, tmpl) ->
    data =
      questionnaire: @questionnaire
      visit: @visit
      patient: @patient
      readonly: true
    __showQuestionnaireWizzard data
    false

  #this visit patient
  "click .openVisit": (evt) ->
    visit = @visit
    patient = @patient
    if visit.designVisitId?
      Session.set 'selectedDesignVisitId', visit.designVisitId
    else
      Session.set 'selectedDesignVisitId', visit._id
