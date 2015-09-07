Template.empaticaRecorder.rendered = ->
  Session.set 'empatica_sessionId', @data.sessionId
  authenticate()

Template.empaticaRecorder.helpers
  isAuthenticating: ->
    Session.get("empatica_isAuthenticating")
  isAuthenticated: ->
    Session.get("empatica_isAuthenticated")
  authenticationError: ->
    Session.get("empatica_authenticationError")
  isDiscovering: ->
    Session.get("empatica_isDiscovering")
  discoveredDevices: ->
    Session.get("empatica_discoveredDevices")
  #hasSelectedDevices: ->
  #  Session.get("selectedDevices")
  isConnecting: ->
    Session.get("empatica_isConnecting")
  isConnected: ->
    Session.get("empatica_isConnected")
  isRecording: ->
    Session.get("empatica_isRecording")

Template.empaticaRecorder.events
  "click #authenticate": (evt) ->
    authenticate()

  "click #discoverDevices": (evt) ->
    discover()

  "click #connectDevices": (evt) ->
    connect()

  "click #disconnectDevices": (evt) ->
    disconnect()
    
  "click #startRecording": (evt) ->
    startRecording()

  "click #stopRecording": (evt) ->
    stopRecording()

  "click #listRecords": (evt) ->
    listRecords()


authenticate = ->
  Session.set("empatica_isAuthenticating", true)
  window.plugins.Empatica.authenticateWithAPIKey("47a21adb8f154caba25b50feaa9a5eec", (msg) ->
    Session.set("empatica_isAuthenticated", true)
    Session.set("empatica_isAuthenticating", false)
    Session.set("empatica_authenticationError", false)
    discover()
  , (msg) ->
    Session.set("empatica_isAuthenticated", false)
    Session.set("empatica_isAuthenticating", false)
    Session.set("empatica_authenticationError", "Initializing the Empatica API failed with the following error: '#{msg}'. Are you sure you are connected to the internet?")
  )
  false

discover = ->
  Session.set("empatica_isDiscovering", true)
  window.plugins.Empatica.discoverDevices( (devices)->
    console.log "did discover devices!"
    Session.set("empatica_isDiscovering", false)
    Session.set("empatica_discoveredDevices", devices)
    #TODO set 1 to 2
    if devices.length < 2 and !Session.get('empatica_isConnecting') and !Session.get('empatica_isConnected')
      discover()
    else if devices.length is 2
      connect()
  , (error) ->
    console.log "discovery error:"
    console.log error
    Session.set("empatica_isDiscovering", false)
  )
  false

connect = ->
  Session.set("empatica_isConnecting", true)
  devices = Session.get("empatica_discoveredDevices")
  if devices.length is 0
    return false
  window.plugins.Empatica.connectDevices(devices,
  (msg)->
    console.log "did connect devices!"
    console.log msg
    Session.set("empatica_isConnected", true)
    Session.set("empatica_isConnecting", false)
  , (error) ->
    console.log "discovery error:"
    console.log error
    Session.set("empatica_isConnected", false)
    Session.set("empatica_isConnecting", false)
  )
  false

disconnect = ->
  window.plugins.Empatica.disconnectAllDevices( (msg)->
    console.log "disconnectAllDevices done!"
    console.log msg
    Session.set("empatica_isConnected", false)
  , (error) ->
    console.log "disconnectAllDevices error:"
    console.log error
    Session.set("empatica_isConnected", false)
  )
  false

#uploadInterval = null
startRecording = ->
  sessionId = Session.get("empatica_sessionId")
  console.log "startRecording with sessionId:"+sessionId
  window.plugins.Empatica.startRecording(sessionId,
  (msg)->
    console.log "recording: "
    console.log msg
    Session.set("empatica_isRecording", true)
    #uploadInterval = Meteor.setInterval(uploadRecords, 5000)
  , (error) ->
    console.log "recording error:"
    console.log error
    if error.code is "missing_device"
      Session.set("empatica_discoveredDevices", null)
      Session.set("empatica_isConnected", false)
      discover()
    Session.set("empatica_isRecording", false)
  )
  false

stopRecording = ->
  window.plugins.Empatica.stopRecording( (msg)->
    console.log "stopRecording: "
    console.log msg
    Session.set("empatica_isRecording", false)
    #Meteor.clearInterval(uploadInterval)
    uploadRecords()
  , (error) ->
    console.log "stopRecording error:"
    console.log error
    Session.set("empatica_isRecording", false)
  )
  false

uploadRecords = ->
  window.plugins.Empatica.listRecords( (records)->
    console.log "listRecords: "
    sessionId = Session.get('empatica_sessionId')
    _.each records, (record) ->
      filename = record.substr(record.lastIndexOf('/')+1)
      er = EmpaticaRecords.findOne
        name: filename
      unless er?
        upload(record, sessionId)
  , (error) ->
    console.log "listRecords error:"
    console.log error
  )

upload = (fileURL, sessionId)->
  win = (r) ->
    console.log 'Code = ' + r.responseCode
    console.log 'Response = ' + r.response
    console.log 'Sent = ' + r.bytesSent
    return

  fail = (error) ->
    alert 'An error has occurred: Code = ' + error.code
    console.log 'upload error source ' + error.source
    console.log 'upload error target ' + error.target
    return

  options = new FileUploadOptions
  options.fileKey = 'file'
  options.fileName = fileURL.substr(fileURL.lastIndexOf('/') + 1)
  options.mimeType = 'text/plain'
  options.httpMethod = 'PUT'
  options.headers = 
    'Content-Type': "text/plain"
  params = {}
  params.filename = options.fileName
  params.sessionId = sessionId
  options.params = params
  ft = new FileTransfer
  ft.upload fileURL, encodeURI(Meteor.absoluteUrl()+'/cfs/files/empaticaRecords?filename='+options.fileName), win, fail, options
