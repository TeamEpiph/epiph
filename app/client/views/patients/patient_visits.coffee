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
  "click .answerQuestionnaire": (evt, tmpl) ->
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
