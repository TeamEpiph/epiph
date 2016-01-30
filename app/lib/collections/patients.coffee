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
