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
