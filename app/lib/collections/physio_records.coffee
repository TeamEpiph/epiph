@PhysioRecords = new (FS.Collection)('physioRecords',
  stores: [ 
    new (FS.Store.FileSystem)('physioRecords', 
      path: '~/physio_records'
    ) 
  ]
  beforeWrite: (fileObj) ->
    console.log fileObj
    name = "#{fileObj.metadata.visitId}_#{fileObj.metadata.sensor}.csv"
    {
      name: name
      extension: 'csv'
      type: 'text/csv'
    }
)

#FIXME
allowPhysioRecordAccess = (userId, doc) ->
  if doc.metadata? and doc.metadata.visitId?
    visit = Visits.findOne doc.metadata.visitId
    if visit?
      patient = Patients.findOne visit.patientId
      if patient?
        if Roles.userIsInRole(userId, ['admin']) or 
        (Roles.userIsInRole(userId, 'therapist') and patient.therapistId is userId)
          return true
  false

PhysioRecords.allow
  insert: (userId, doc) ->
    allowPhysioRecordAccess(userId, doc)
  update: (userId, doc, fieldNames, modifier) ->
    allowPhysioRecordAccess(userId, doc)
  remove: (userId, doc) ->
    allowPhysioRecordAccess(userId, doc)
  download: (userId, doc) ->
    allowPhysioRecordAccess(userId, doc)
