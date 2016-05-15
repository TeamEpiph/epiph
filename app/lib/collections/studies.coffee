class @Study
  constructor: (doc) ->
    _.extend this, doc

  creator: ->
    Meteor.users.findOne _id: @creatorId

  editingNotAllowed: ->
    false

@Studies = new Meteor.Collection("studies",
  transform: (doc) ->
    new Study(doc)
)

Studies.before.insert BeforeInsertTimestampHook
Studies.before.update BeforeUpdateTimestampHook

Meteor.methods
  "createStudy": ->
    checkIfAdmin()
    Studies.insert
      title: "new Study"
      creatorId: Meteor.userId()
    return

  "updateStudyTitle": (studyId, title) ->
    checkIfAdmin()
    check(title, String)
    study = Studies.findOne studyId
    throw new Meteor.Error(403, "study not found.") unless study?
    throw new Meteor.Error(400, "Study is locked. Please unlock it first.") if study.isLocked
    Studies.update studyId,
      $set: title: title
    return

if Meteor.isServer
  Meteor.methods
    "lockStudy": (studyId, forceReason) ->
      checkIfAdmin() 
      check studyId, String
      check forceReason, String

      study = Studies.findOne studyId
      throw new Meteor.Error(403, "study not found.") unless study?
      throw new Meteor.Error(400, "study is already locked.") if study.isLocked

      Meteor.call "logActivity", "lock study (#{study.title})", "notice", forceReason, null

      Studies.update studyId,
        $set: isLocked: true
      return

    "unlockStudy": (studyId, forceReason) ->
      checkIfAdmin() 
      check studyId, String
      check forceReason, String

      study = Studies.findOne studyId
      throw new Meteor.Error(403, "study not found.") unless study?
      throw new Meteor.Error(400, "study is already unlocked.") if study.isLocked? and !study.isLocked

      Meteor.call "logActivity", "unlock study (#{study.title})", "notice", forceReason, null

      Studies.update studyId,
        $set: isLocked: false
      return

    "removeStudy": (studyId, forceReason) ->
      checkIfAdmin() 
      check studyId, String

      study = Studies.findOne studyId
      throw new Meteor.Error(403, "study not found.") unless study?
      throw new Meteor.Error(400, "study is locked. Please unlock it first.") if study.isLocked

      #check if a visit with answer exists
      visitTemplateIds = []
      StudyDesigns.find(
        studyId: studyId
      ).forEach (sd) ->
        sd.visits.forEach (vt) ->
          visitTemplateIds.push vt._id

      visitIds = Visits.find(
        designVisitId: $in: visitTemplateIds
      ).map (v) -> v._id

      hasData = Answers.find(visitId: $in: visitIds).count() > 0
      if hasData and !forceReason?
        throw new Meteor.Error(400, "answersExistForStudy")

      if hasData
        Meteor.call "logActivity", "remove study (#{study.title}) which has data", "critical", forceReason, study
      else
        Meteor.call "logActivity", "remove empty study (#{study.title})", "notice", null, study

      Answers.remove
        visitId: $in: visitIds
      Visits.remove
        designVisitId: $in: visitTemplateIds
      Patients.remove
        studyId: studyId
      StudyDesigns.remove
        studyId: studyId
      Studies.remove
        _id: studyId
      return
