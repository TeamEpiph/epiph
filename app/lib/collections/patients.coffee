class @Patient
  constructor: (doc) ->
    _.extend this, doc

@Patients = new Meteor.Collection("patients",
  transform: (doc) ->
    new Patient(doc)
)

if Meteor.isServer
  Patients._ensureIndex( { id: 1 }, { unique: true } )


Patients.before.insert BeforeInsertTimestampHook
Patients.before.update BeforeUpdateTimestampHook
