Template.patients.onCreated ->
  @subscribe("patients")

Template.patients.helpers
  openPatients: ->
    openPatientIds = Session.get("openPatientIds")
    return null if !openPatientIds? or openPatientIds.length is 0
    Patients.find
      _id: {$in: Session.get("openPatientIds")}

  selectedPatient: ->
    return null if !Session.get("selectedPatientId")?
    Patients.findOne
      _id: Session.get("selectedPatientId")
  
  #this openPatient
  patientTabClasses: ->
    if @_id is Session.get("selectedPatientId")
      return "active"
    ""
  #this openPatient
  isSelectedPatient: ->
    @_id is Session.get("selectedPatientId")


Template.patients.events
  "click #createPatient": (evt) ->
    Meteor.call "createPatient", (error, patientId) ->
      throwError error if error?
      openPatientIds = Session.get("openPatientIds") or []
      openPatientIds.push patientId
      openPatientIds = _.uniq openPatientIds
      Session.set "openPatientIds", openPatientIds
      Session.set "selectedPatientId", patientId
      evt.target.blur()

  "click .selectPatient": (evt) ->
    evt.preventDefault()
    Session.set "selectedPatientId", @_id

  "submit #openPatient": (evt) ->
    evt.preventDefault()
    patientId = evt.target.patientId.value
    console.log "openPatient #{patientId}"
    openPatientIds = Session.get("openPatientIds") or []
    openPatientIds.push patientId
    openPatientIds = _.uniq openPatientIds
    Session.set "openPatientIds", openPatientIds
    Session.set "selectedPatientId", patientId
    evt.target.patientId.value = ""
    evt.target.patientId.blur()

  "click .closePatient": (evt) ->
    evt.stopPropagation()
    evt.preventDefault()
    patientId = @_id
    openPatientIds = Session.get("openPatientIds") or []
    oldIndex = 0
    openPatientIds = openPatientIds.filter (pId, index) ->
      if pId is patientId
        oldIndex = index
        return false
      true
    if patientId is Session.get("selectedPatientId") and openPatientIds.length > 0
      index = oldIndex-1
      index = 0 if oldIndex<0
      Session.set("selectedPatientId", openPatientIds[index])
    if openPatientIds.length is 0
      Session.set("selectedPatientId", null)
    Session.set "openPatientIds", openPatientIds
    return


Template.registerHelper "patientAbbrev", (patientId) ->
  if patientId?
    "@#{patientId.substring(0, 6)}"
  else
    "patientAbbrev no patientId: #{patientId}"
