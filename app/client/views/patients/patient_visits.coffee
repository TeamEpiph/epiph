Template.patientVisits.helpers
  visits: ->
    patient = @patient
    studyDesign = patient.studyDesign()
    if studyDesign?
      visits = studyDesign.visits.map (designVisit) ->
        visit = Visits.findOne
          designVisitId: designVisit._id
          patientId: patient._id
        visit = new Visit(designVisit) if !visit?
        visit.validatedDoc()
      visits

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
    Modal.show('questionnaireWizzard', @)
    false

  #this visit patient
  "click .openVisit": (evt) ->
    visit = Visits.findOne
      _id: @visit._id
      patientId: @patient._id
    if visit?
      openVisit(visit, @patient)
    else
      if @visit.patientId?
        throw new Meteor.Error(403, "patient visit not found")
      patient = @patient
      Meteor.call "initVisit", @visit._id, @patient._id, (error, _id) ->
        throwError error if error?
        visit = Visits.findOne _id
        openVisit(visit, patient)

openVisit = (visit, patient) ->
  openPatientVisit = Session.get("openPatientVisit") or {}
  openPatientVisit[patient._id] = 
    title: visit.title
    _id: visit._id
  Session.set("openPatientVisit", openPatientVisit)
  Session.set "patientTab", 
    title: visit.title
    visitId: visit._id
    template: "patientVisit"
  false
