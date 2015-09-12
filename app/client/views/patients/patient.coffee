Template.patient.created = ->
  @subscribe "studyForPatient", @data._id
  @subscribe "studyDesignForPatient", @data._id
  @subscribe "visitsForPatient", @data._id

Template.patient.helpers
  tabs: ->
    tabs = [
      title: "Visits"
      template: "patientVisits"
    ]
    if @activeVisitId?
      tabs.push
        title: "active visit"
        template: "patientVisit"
    tabs

  #this tab
  tabClasses: ->
    tab = Session.get("patientTabTemplate")
    if @template is tab
      return "active"
    ""

  template: ->
    tab = Session.get("patientTabTemplate")
    if !tab? or !@activeVisitId
      tab = "patientVisits"
    tab

  numVisits: ->
    Visits.find(
      patientId: @_id
    ).count()
    

Template.patient.events
  "click .switchTab": (evt) ->
    Session.set("patientTabTemplate", @template)
    false


Template.patientVisits.helpers
  visits: ->
    studyDesign = @studyDesign()
    if studyDesign?
      visits = @studyDesign().visits
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

    Patients.update @patient._id,
      $set:
        activeVisitId: visit._id
    Session.set("patientTabTemplate", "patientVisit")
    false
     

Template.patientVisit.created = ->
  @subscribe "physioRecordsForVisit", @data.activeVisitId
  @subscribe "questionnaires"

Template.patientVisit.helpers
  visit: ->
    Visits.findOne @activeVisitId

  #this visit
  questionnaires: ->
    qIds = @questionnaireIds or []
    Questionnaires.find
      _id: {$in: qIds}

  #this visit
  showEmpaticaRecorder: ->
    @recordPhysicalData and Meteor.isCordova

  #this visit
  empaticaSessionId: ->
    @_id
    
  #this visit
  physioRecords: ->
    PhysioRecords.find
      'metadata.visitId': @_id

