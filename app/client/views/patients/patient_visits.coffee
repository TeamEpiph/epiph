Template.patientVisits.helpers
  visits: ->
    patient = @patient
    studyDesign = patient.studyDesign()
    if studyDesign?
      visits = studyDesign.visits.map (designVisit) ->
        visit = Visits.findOne
          designVisitId: designVisit._id
          patientId: patient._id
        #dummy visit for validation to work
        visit = new Visit(designVisit) if !visit?
        visit.validatedDoc()
      visits.sort (a,b) ->
        a.index - b.index
      previousDate = null
      visits.forEach (v) ->
        date = null
        if v.date
          previousDate = moment(v.date)
        else
          if v.day? and previousDate?
            v.date = previousDate.add(v.day, 'days')
            previousDate = moment(v.date)
        if !v.date?
          v.dateCSS = "no-date"
        else 
          date = moment(v.date)
          now = moment()
          if date.year() is now.year() and date.dayOfYear() is now.dayOfYear()
            v.dateCSS = "due"
          else if date.isBefore(now)
            v.dateCSS = "over-due"
          else
            v.dateCSS = "future"
      visits

  visitDateEO: ->
    visit = @visit
    patient = @patient
    date = null
    if visit.date?
      date = fullDate(visit.date)
    value: date
    emptytext: "no date set"
    success: (response, newVal) ->
      if newVal.length is 0
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
