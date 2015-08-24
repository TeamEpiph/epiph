@EmpaticaRecords = new (FS.Collection)('empaticaRecords',
  stores: [ 
    new (FS.Store.FileSystem)('empaticaRecords', 
      path: '~/empatica_records'
    ) 
  ]
  beforeWrite: (fileObj) ->
    console.log fileObj
)

#FIXME
EmpaticaRecords.allow
  insert: (userId, doc) ->
    true
  update: (userId, doc, fieldNames, modifier) ->
    true
  remove: (userId, doc) ->
    true
  download: (userId, doc) ->
    true
