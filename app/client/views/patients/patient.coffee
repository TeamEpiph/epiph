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
  designs: ->
    ds = ""
    designs = @studyDesigns().forEach (d) ->
      ds += d.title+', '
    ds.slice(0, -2)

  numVisits: ->
    visits = 0
    @studyDesigns().forEach (d) ->
      visits += d.visits.length if d?
    visits

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
