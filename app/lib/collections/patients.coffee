class @Patient
  constructor: (doc) ->
    _.extend this, doc

  therapist: ->
    return null unless @therapistId?
    Meteor.users.findOne _id: @therapistId

  therapistName: ->
    t = @therapist()
    return if !t?
    t.profile.name

  study: ->
    return null unless @studyId?
    Studies.findOne _id: @studyId

  studyDesign: ->
    return null unless @studyDesignId?
    StudyDesigns.findOne _id: @studyDesignId


@Patients = new Meteor.Collection("patients",
  transform: (doc) ->
    new Patient(doc)
)

if Meteor.isServer
  Patients._ensureIndex( { id: 1 }, { unique: true } )


Patients.before.insert BeforeInsertTimestampHook
Patients.before.update BeforeUpdateTimestampHook

Meteor.methods
  'updatePatients': (ids, update) ->
    check(ids, [String])
    check(update, Object)
    #TODO check if allowed

    #pick whitelisted keys
    update = _.pickDeep update,
    "$set.therapistId",
    "$set.studyDesignId",
    "$set.hrid",
    "$unset.therapistId",
    "$unset.studyDesignId",
    "$unset.hrid"

    ids.forEach (id) ->
      Patients.update _id: id, update


  "removePatient": (patientId) ->
    check patientId, String

    patient = Patients.findOne patientId
    throw new Meteor.Error(500, "Patient can't be found.") unless patient?

    if patient.isExcluded
      throw new Meteor.Error(500, "This patient is already excluded from the study and therefor can't be deleted.")

    if patient.hasData
      throw new Meteor.Error(500, "This patient's record can't be deleted, because there is already data attached to it. Please exclude him/her instead.")

    Visits.remove
      patientId: @_id
    Patients.remove
      _id: patientId
    return


  "excludePatient": (patientId, reason) ->
    check patientId, String
    check reason, String

    patient = Patients.findOne patientId
    throw new Meteor.Error(500, "Patient can't be found.") unless patient?

    Patients.update patientId,
      $set:
        isExcluded: true
        excludeReason: reason
        excludedAt: Date.now()

    return
