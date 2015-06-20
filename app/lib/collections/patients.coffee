class @Patient
  constructor: (doc) ->
    _.extend this, doc

  therapist: ->
    return null unless @therapistId?
    Meteor.users.findOne _id: @therapistId

  study: ->
    return null unless @studyId?
    Studies.findOne _id: @studyId

@Patients = new Meteor.Collection("patients",
  transform: (doc) ->
    new Patient(doc)
)

if Meteor.isServer
  Patients._ensureIndex( { id: 1 }, { unique: true } )


Patients.before.insert BeforeInsertTimestampHook
Patients.before.update BeforeUpdateTimestampHook
