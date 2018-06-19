class @Patient
  constructor: (doc) ->
    _.extend this, doc

  caseManager: ->
    return null unless @caseManagerId?
    Meteor.users.findOne _id: @caseManagerId

  caseManagerName: ->
    getUserDescription @caseManager()

  study: ->
    return null unless @studyId?
    Studies.findOne _id: @studyId

  studyDesigns: ->
    return [] unless @studyDesignIds?
    StudyDesigns.find
      _id: $in: @studyDesignIds
    ,
      sort: createdAt: 1

  languages: ->
    langs = ""
    langs += @primaryLanguage if @primaryLanguage?
    if @secondaryLanguage
      langs += ", #{@secondaryLanguage}"
    langs


@Patients = new Meteor.Collection("patients",
  transform: (doc) ->
    new Patient(doc)
)

if Meteor.isServer
  Patients._ensureIndex( { id: 1 }, { unique: true } )


Patients.before.insert BeforeInsertTimestampHook
Patients.before.update BeforeUpdateTimestampHook

schema =
  'id':
    type: String
  'hrid':
    type: String
    optional: true
    unique: true
    index: true
  'creatorId':
    type: String
  'studyId':
    type: String
  'studyDesignId':
    type: String
    optional: true
  'studyDesignIds':
    type: [String]
    optional: true
  'caseManagerId':
    type: String
    optional: true
  'primaryLanguage':
    type: String
    optional: true
  'secondaryLanguage':
    type: String
    optional: true
  'hasData':
    type: Boolean
    defaultValue: false
  'hasDataForDesignIds':
    type: [String]
    optional: true
  'isExcluded':
    type: Boolean
    defaultValue: false
  'excludesIncludes':
    type: [Object]
    optional: true
  'excludesIncludes.$.reason':
    type: String
  'excludesIncludes.$.createdAt':
    type: Number
  'updatedAt':
    type: Number
    optional: true
  'createdAt':
    type: Number
    optional: true
Patients.attachSchema new SimpleSchema(schema)

if Meteor.isServer
  Meteor.methods
    "createPatient": (studyId) ->
      canAddPatient(studyId)
      check studyId, String
      study = Studies.findOne studyId
      throw new Meteor.Error(403, "study not found.") unless study?
      throw new Meteor.Error(400, "Study is locked. Please unlock it first.") if study.isLocked

      _id = null
      tries = 0
      loop
        try
          _id = Patients.insert
            id: readableRandom(6)
            creatorId: Meteor.userId()
            studyId: studyId
            hasData: false
            caseManagerId: Meteor.userId()
        catch e
          console.log "Error: createPatient"
          console.log e
        finally
          tries += 1
          break if _id or tries >= 10
      throw new Meteor.Error(500, "Can't create patient, id space seems to be full.") unless _id?
      return _id

Meteor.methods
  'updatePatients': (ids, update) ->
    check ids, [String]
    check update, Object
    ids.forEach((patientId) -> canUpdatePatient(patientId))

    allowedKeys = [
      "$set.caseManagerId",
      "$set.studyDesignIds",
      "$set.primaryLanguage",
      "$set.secondaryLanguage",
      "$unset.primaryLanguage",
      "$unset.secondaryLanguage",
    ]

    if Roles.userIsInRole(Meteor.user(), 'admin')
      allowedKeys = [
        allowedKeys...,
        "$unset.caseManagerId",
        "$unset.studyDesignIds"
      ]

    if ids.length > 1
      if update['$set']? #don't overwrite with empty values
        delete update['$unset']
    else if ids.length is 1
      allowedKeys = _.union allowedKeys, [
        "$set.hrid",
        "$unset.hrid"
      ]

    # If no study designs are selected store an empty array
    if update['$unset']? and update['$set']? and update['$unset']['studyDesignIds']?
      delete update['$unset']['studyDesignIds']
      update['$set']['studyDesignIds'] = []

    #pick whitelisted keys
    update = _.pickDeep update, allowedKeys

    Patients.find(_id: $in: ids).forEach (p) ->
      study = Studies.findOne p.studyId
      throw new Meteor.Error(403, "study not found.") unless study?
      throw new Meteor.Error(400, "Study is locked. Please unlock it first.") if study.isLocked

    #check if changing studyDesign for a patient which has data
    if update['$set']?['studyDesignIds']? or update['$unset']?['studyDesignIds']?
      patientIds = []
      Patients.find(_id: $in: ids).forEach (p) ->
        # unset is always a string
        if update['$unset']?['studyDesignIds']? and p.hasData
          patientIds.push p.id
        if p.hasDataForDesignIds?
          if update['$set']?['studyDesignIds']?
            allFound = true
            p.hasDataForDesignIds.forEach (sDId) ->
              if update['$set']['studyDesignIds'].indexOf(sDId) is -1
                allFound = false
            if !allFound
              patientIds.push p.id

      if patientIds.length > 0
        throw new Meteor.Error(400, "You have removed one or more study designs from patient(s) (#{patientIds.join(', ')}) which have already entered data for one of these designs. This is not allowed and your changes are therefore discarded.")

      #remove already created visits with no data
      Patients.find(_id: $in: ids).forEach (p) ->
        Visits.find( patientId: p._id ).forEach (v) ->
          if Answers.find( visitId: v._id).count() is 0
            Visits.remove _id: v._id

    ids.forEach (id) ->
      try
        Patients.update _id: id, update
      catch e
        if e.code is 11000 #MongoError: E11000 duplicate key error
          throw new Meteor.Error(400, "The HRID you entered exists already, please choose a unique value.")
        else
          throw e
    return

  "excludePatient": (patientId, reason) ->
    checkIfAdmin()
    check patientId, String
    check reason, String

    patient = Patients.findOne patientId
    throw new Meteor.Error(500, "Patient can't be found.") unless patient?
    throw new Meteor.Error(500, "Patient is already excluded.") if patient.isExcluded
    study = Studies.findOne patient.studyId
    throw new Meteor.Error(403, "study not found.") unless study?
    throw new Meteor.Error(400, "Study is locked. Please unlock it first.") if study.isLocked

    Patients.update patientId,
      $push: excludesIncludes:
        reason: reason
        createdAt: Date.now()

    Patients.update patientId,
      $set: isExcluded: true
    return

  "includePatient": (patientId, reason) ->
    checkIfAdmin()
    check patientId, String
    check reason, String

    patient = Patients.findOne patientId
    throw new Meteor.Error(500, "Patient can't be found.") unless patient?
    throw new Meteor.Error(500, "Patient isn't excluded.") if !patient.isExcluded
    study = Studies.findOne patient.studyId
    throw new Meteor.Error(403, "study not found.") unless study?
    throw new Meteor.Error(400, "Study is locked. Please unlock it first.") if study.isLocked

    Patients.update patientId,
      $push: excludesIncludes:
        reason: reason
        createdAt: Date.now()

    Patients.update patientId,
      $set: isExcluded: false
    return

  "removePatient": (patientId, forceReason) ->
    check patientId, String
    canUpdatePatient(patientId)

    patient = Patients.findOne patientId
    throw new Meteor.Error(500, "Patient can't be found.") unless patient?
    study = Studies.findOne patient.studyId
    throw new Meteor.Error(403, "study not found.") unless study?
    throw new Meteor.Error(400, "Study is locked. Please unlock it first.") if study.isLocked

    if patient.hasData and !forceReason
      throw new Meteor.Error(500, "patientHasData")

    if patient.hasData
      Meteor.call "logActivity", "remove patient (#{patient.id}) which has data", "critical", forceReason, patient
    else
      Meteor.call "logActivity", "remove patient (#{patient.id}) which has no data", "notice", null, patient

    Visits.find(patientId: patientId).forEach (v) ->
      Answers.remove visitId: v._id
      Visits.remove v._id

    Patients.remove
      _id: patientId
    return
