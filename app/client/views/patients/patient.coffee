Template.patient.created = ->
  @autorun ->
    patient = Patients.findOne Session.get("selectedPatientId")
    if patient?
      #these subscriptions will cleanup automatically
      #Meteor docs: If you call Meteor.subscribe within a reactive computation, for example using Tracker.autorun, the subscription will automatically be cancelled when the computation is invalidated or stopped
      #Meteor.subscribe("studyForPatient", patient._id)
      #Meteor.subscribe("studyDesignForPatient", patient._id)
      #Meteor.subscribe("combinedVisitsDataForPatient", patient._id)
      Meteor.subscribe("studyCompositesForPatient", patient._id)
      Meteor.subscribe("visitsCompositeForPatient", patient._id)

Template.patient.helpers
  numVisits: ->
    #Visits.find(
    #  patientId: @_id
    #).count()
    studyDesign = @studyDesign()
    if studyDesign?
      studyDesign.visits.length
    else
      0

  template: ->
    selectedDesignVisitId = Session.get 'selectedDesignVisitId'
    if selectedDesignVisitId?
      "patientVisit"
    else
      "patientVisits"

  templateData: ->
    patient: @
