@ExportCSVs = new (FS.Collection)('exportCSVs',
  stores: [ 
    new FS.Store.GridFS('exportsCSVs')
  ]
)

ExportCSVs.allow
  download: (userId, doc) ->
    Roles.userIsInRole(userId, ['admin'])

SyncedCron.add
  name: 'remove old exports'
  schedule: (parser) ->
    # parser is a later.parse object
    parser.text 'every 10 minute'
  job: ->
    validFor = 20 * 60 * 1000 #20min
    find =
      'metadata.createdAt':
        $lt: Date.now()-validFor
    count = ExportCSVs.find(find).count()
    ExportCSVs.remove find
    "#{count} old exports removed"

#FS.debug = true
Future = Npm.require('fibers/future')
Meteor.methods
  'createCSV': (selection, loginToken) ->	
    checkIfAdmin()
    check selection, Object
    check loginToken, String

    #https://github.com/CollectionFS/Meteor-CollectionFS/blob/master/packages/access-point/access-point-common.js
    authObject = 
      authToken: loginToken
    authString = JSON.stringify(authObject)
    authToken = FS.Utility.btoa(authString)

    csv = ""
    separator = ';'
    Export.columnHeaders(selection).forEach (header) ->
      csv += '"'+header.title+'"'+separator
    csv += '\n'

    Export.rows(selection).forEach (row) ->
      Export.columns(selection, row).forEach (col) ->
        csv += '"'+col+'"'+separator
      csv += '\n'

    #console.log csv

    #insert file into collection and return download url
    future = new Future
    buffer = new Buffer(csv, "utf-8")
    newFile = new FS.File
    newFile.name "export_#{moment().toISOString()}.csv"
    newFile.metadata =
      createdAt: Date.now()
      userId: Meteor.userId()
    newFile.attachData buffer, { type: 'text/csv' }, (error) ->
      if error?
        future.throw error
        return
      ExportCSVs.insert newFile, (err, fileObj) ->
        if err?
          future.throw err
          return
        urlRetrieveCount = 0
        onStored = Meteor.bindEnvironment((->
          if urlRetrieveCount > 20
            future.throw new Error('Too much url retrieval attempts for export.')
            return
          url = fileObj.url { auth: authToken }
          if url
            future.return url
          else
            urlRetrieveCount++
            setTimeout onStored, 500
          return
        ), (error) ->
          future.throw error
          return
        )
        fileObj.once 'stored', onStored

    future.wait()
    url = future.get()
    url
