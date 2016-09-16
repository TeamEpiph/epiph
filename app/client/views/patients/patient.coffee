Template.patient.created = ->
  self = @
  @autorun ->
    Session.set 'patientSubscriptionsReady', false
    patient = Patients.findOne Session.get("selectedPatientId")
    if patient?
      self.subscribe("studyCompositesForPatient", patient._id)
      self.subscribe("visitsCompositeForPatient", patient._id, onReady: -> Session.set 'patientSubscriptionsReady', true)

Template.patient.rendered = ->
  @$('[data-toggle=tooltip]').tooltip()

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

Template.patient.events
  "click .id, click .hrid": (evt) ->
    selectPatientId(@_id, true)
