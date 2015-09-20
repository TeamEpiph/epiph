Template.patient.created = ->
  @autorun ->
    patient = Patients.findOne Session.get("selectedPatientId")
    if patient?
      #these subscriptions will cleanup automatically
      #Meteor docs: If you call Meteor.subscribe within a reactive computation, for example using Tracker.autorun, the subscription will automatically be cancelled when the computation is invalidated or stopped
      Meteor.subscribe("studyForPatient", patient._id)
      Meteor.subscribe("studyDesignForPatient", patient._id)
      Meteor.subscribe("visitsForPatient", patient._id)
      if patient.runningVisitId?
        Session.set "patientTab", 
          title: "running visit"
          visitId: patient.runningVisitId
          template: "patientVisit"
      else
        openPatientVisit = Session.get("openPatientVisit")
        if openPatientVisit? and openPatientVisit[patient._id]?
          v = openPatientVisit[patient._id]
          Session.set "patientTab", 
            visitId: v._id
            template: "patientVisit"
        else
          Session.set "patientTab", 
            title: "Visits"
            template: "patientVisits"

Template.patient.helpers
  numVisits: ->
    Visits.find(
      patientId: @_id
    ).count()
    
  tabs: ->
    tabs = [
      title: "Visits"
      template: "patientVisits"
    ]
    if @runningVisitId?
      tabs.push
        title: "running visit"
        visitId: @runningVisitId
        template: "patientVisit"
    openPatientVisit = Session.get("openPatientVisit")
    if openPatientVisit? and openPatientVisit[@_id] and openPatientVisit[@_id]._id isnt @runningVisitId
      v = openPatientVisit[@_id]
      tabs.push
        title: v.title
        visitId: v._id
        template: "patientVisit"
    tabs

  #this tab
  tabClasses: ->
    tab = Session.get("patientTab")
    if @template is tab.template and (!tab.visitId? or (tab.visitId? and tab.visitId is @visitId))
      return "active"
    ""

  template: ->
    Session.get("patientTab").template

  templateData: ->
    data = 
      patient: @
    if Session.get("patientTab").visitId?
      data.visitId = Session.get("patientTab").visitId
    data

Template.patient.events
  "click .switchTab": (evt) ->
    Session.set("patientTab", @)
    false
