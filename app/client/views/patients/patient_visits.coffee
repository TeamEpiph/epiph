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

Template.patientVisitsTr.helpers
  #this visit
  visitCSS: ->
    return "valid" if @valid
    "invalid"
  #this questionnaire
  questionnaireCSS: ->
    return "valid" if @answered
    "invalid"
  #this visit
  physioRecordsCSS: ->
    return "valid" if @physioValid
    "invalid"


Template.patientVisits.events
  "click .openVisit": (evt) ->
    visit = Visits.findOne
      _id: @visit._id
      patientId: @patient._id
    unless visit?
      if @visit.patientId?
        throw new Meteor.Error(403, "patient visit not found")
      #we copy the data here from the visit template to
      #an actuall existing visit here
      #TODO cleanup copy
      visit = 
        patientId: @patient._id
        designVisitId: @visit._id
        title: @visit.title
        questionnaireIds: @visit.questionnaireIds
        recordPhysicalData: @visit.recordPhysicalData
      #TODO migrate to method call
      id = Visits.insert visit
      visit = Visits.findOne id

    openPatientVisit = Session.get("openPatientVisit") or {}
    openPatientVisit[@patient._id] = 
      title: visit.title
      _id: visit._id
    Session.set("openPatientVisit", openPatientVisit)
    Session.set "patientTab", 
      title: visit.title
      visitId: visit._id
      template: "patientVisit"
    false
