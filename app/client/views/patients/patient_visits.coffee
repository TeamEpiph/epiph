Template.patientVisits.helpers
  visits: ->
    studyDesign = @patient.studyDesign()
    if studyDesign?
      visits = studyDesign.visits
      visits

Template.patientVisits.events
  "click .openVisit": (evt) ->
    visit = Visits.findOne
      patientId: @patient._id
      designVisitId: @visit._id
    unless visit?
      #we copy the data here from the visit template to
      #an actuall existing visit here
      #TODO cleanup copy
      visit = 
        patientId: @patient._id
        designVisitId: @visit._id
        title: @visit.title
        questionnaireIds: @visit.questionnaireIds
        recordPhysicalData: @visit.recordPhysicalData
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
