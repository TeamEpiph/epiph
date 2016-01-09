@PhysioRecords = new (FS.Collection)('physioRecords',
  stores: [ 
    new (FS.Store.FileSystem)('physioRecords', 
      path: '~/physio_records'
    ) 
  ]
)

allowPhysioRecordAccess = (userId, doc) ->
  console.log doc
  if doc.metadata? and doc.metadata.visitId?
    visit = Visits.findOne doc.metadata.visitId
    if visit?
      patient = Patients.findOne visit.patientId
      if patient?
        if Roles.userIsInRole(userId, ['admin']) or 
        (Roles.userIsInRole(userId, 'therapist') and patient.therapistId is userId)
          return true
  true

PhysioRecords.allow
  insert: (userId, doc) ->
    allowPhysioRecordAccess(userId, doc)
  update: (userId, doc, fieldNames, modifier) ->
    allowPhysioRecordAccess(userId, doc)
  remove: (userId, doc) ->
    false
  download: (userId, doc) ->
    allowPhysioRecordAccess(userId, doc)

Meteor.methods
  "updatePhysioRecordMetadata": (_id, metadata) ->
    check(_id, String)
    check(metadata, Object)
    #TODO check if allowed

    #pick whitelisted keys
    update = _.pickDeep metadata, "visitId", "sensor", "deviceName"
    PhysioRecords.update _id,
      $set:
        'metadata.visitId': update.visitId
        'metadata.sensor': update.sensor
        'metadata.deviceName': update.deviceName
