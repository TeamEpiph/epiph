class @Patient
  constructor: (doc) ->
    _.extend this, doc

@Patients = new Meteor.Collection("patients",
  transform: (doc) ->
    new Patient(doc)
)

Patients.before.insert BeforeInsertTimestampHook
Patients.before.update BeforeUpdateTimestampHook

Meteor.methods
  "createPatient": ->
    checkIfTherapist()
    _id = Patients.insert
      therapistId: Meteor.userId()
    _id
