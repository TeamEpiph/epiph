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

  studyDesign: ->
    return null unless @studyDesignId?
    StudyDesigns.findOne _id: @studyDesignId

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
      checkIfAdmin()
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
    checkIfAdmin()
    check ids, [String]
    check update, Object

    #pick whitelisted keys
    update = _.pickDeep update,
    "$set.caseManagerId",
    "$set.studyDesignId",
    "$set.primaryLanguage",
    "$set.secondaryLanguage",
    "$set.hrid",
    "$unset.caseManagerId",
    "$unset.studyDesignId",
    "$unset.primaryLanguage",
    "$unset.secondaryLanguage",
    "$unset.hrid"

    Patients.find(_id: $in: ids).forEach (p) ->
      study = Studies.findOne p.studyId
      throw new Meteor.Error(403, "study not found.") unless study?
      throw new Meteor.Error(400, "Study is locked. Please unlock it first.") if study.isLocked

    #check if changing studyDesign for a patient which has data
    if update['$set']?['studyDesignId']? or update['$unset']?['studyDesignId']?
      patientIds = []
      Patients.find(_id: $in: ids).forEach (p) ->
        if p.hasData and p.studyDesignId isnt update['$set']['studyDesignId']
          patientIds.push p.id

      if patientIds.length > 0
        throw new Meteor.Error(400, "The following patients are already mapped to another design and have entered data: #{patientIds.join(', ')}. Please remove these IDs from your selection.") 

      #remove already created visits with no data
      Patients.find(_id: $in: ids).forEach (p) ->
        Visits.remove patientId: p._id

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
    checkIfAdmin()
    check patientId, String

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
