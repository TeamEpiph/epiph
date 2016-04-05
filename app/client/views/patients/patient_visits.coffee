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
        if v.date
          v.showDate = true
          previousDate = moment(v.date)
        else
          if v.index is 0
            v.showDate = true
          else if previousDate?
            date = previousDate.add(v.day, 'days')
            if date.isBefore(Date.now())
              css = "due"
            else
              css = "future"
            v.scheduledAt = 
              date: date
              css: css
            previousDate = moment(date)
      visits

  visitDateEO: ->
    visit = @visit
    patient = @patient
    value: fullDate(visit.date)
    emptytext: "no date set"
    defaultValue: fullDate(new Date())
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
    Modal.show('questionnaireWizzard', data, keyboard: false)
    false

  #this visit patient
  "click .openVisit": (evt) ->
    visit = @visit
    patient = @patient
    if visit.designVisitId?
      Session.set 'selectedDesignVisitId', visit.designVisitId
    else
      Session.set 'selectedDesignVisitId', visit._id
