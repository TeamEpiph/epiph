class @StudyDesign
  constructor: (doc) ->
    _.extend this, doc

@StudyDesigns = new Meteor.Collection("study_designs",
  transform: (doc) ->
    new StudyDesign(doc)
)

StudyDesigns.before.insert BeforeInsertTimestampHook
StudyDesigns.before.update BeforeUpdateTimestampHook

schema =
  'title':
    type: String
  'studyId':
    type: String
  'creatorId':
    type: String
  'visits':
    type: [Object]
    optional: true
  'visits._id':
    type: String
  'visits.title':
    type: String
  'visits.index':
    type: Number
#TODO: attach schema
#StudyDesigns.attachSchema new SimpleSchema(schema)

StudyDesigns.allow
  update: (userId, doc, fieldNames, modifier) ->
    #TODO check if allowed
    notAllowedFields = _.without fieldNames, 'title', 'updatedAt'
    return false if notAllowedFields.length > 0
    true

#TODO secure methods
Meteor.methods
  "createStudyDesign": (studyId, title) ->
    count = StudyDesigns.find(
      studyId: studyId
    ).count()
    _id = StudyDesigns.insert
      title: "design #{count+1}"
      studyId: studyId
      creatorId: Meteor.userId()
      visits: [
        _id: new Meteor.Collection.ObjectID()._str
        day: 0
        index: 0
        title: "visit 1"
      ]
    _id

  "removeStudyDesign": (_id) ->
    #TODO: check if allowed
    StudyDesigns.remove
      _id: _id

  "addStudyDesignVisit": (studyDesignId) ->
    check studyDesignId, String

    design = StudyDesigns.findOne
      _id: studyDesignId
    throw new Meteor.Error(500, "StudyDesign #{studyDesignId} not found!") unless design?

    index = design.visits.length
    title = "visit #{index+1}"
    visit =
      _id: new Meteor.Collection.ObjectID()._str
      title: title
      index: index

    StudyDesigns.update
      _id: studyDesignId
    ,
      $push:
        visits: visit

  "changeStudyDesignVisitTitle": (studyDesignId, visitId, title) ->
    check studyDesignId, String
    check visitId, String
    check title, String

    n = StudyDesigns.update
      _id: studyDesignId
      'visits._id': visitId
    ,
      $set:
        'visits.$.title': title
    throw new Meteor.Error(500, "changeStudyVisitTitle: no StudyDesign.visit to update found") unless n > 0

  "changeStudyDesignVisitDay": (studyDesignId, visitId, day) ->
    check studyDesignId, String
    check visitId, String
    day = parseInt(day)
    check day, Number

    n = StudyDesigns.update
      _id: studyDesignId
      'visits._id': visitId
    ,
      $set:
        'visits.$.day': day
    throw new Meteor.Error(500, "changeStudyVisitTitle: no StudyDesign.visit to update found") unless n > 0

  "scheduleQuestionnaireAtVisit": (studyDesignId, visitId, questionnaireId, doSchedule) ->
    check studyDesignId, String
    check visitId, String
    check questionnaireId, String

    find =
      _id: studyDesignId
      'visits._id': visitId

    if doSchedule
      n = StudyDesigns.update find,
        $push:
          'visits.$.questionnaireIds': questionnaireId
    else
      n = StudyDesigns.update find,
        $pull:
          'visits.$.questionnaireIds': questionnaireId
    throw new Meteor.Error(500, "scheduleQuestionnaireAtVisit: no StudyDesign with that visit found") unless n > 0

    updateQuestionnaireIds(studyDesignId)
    return


  "scheduleRecordPhysicalDataAtVisit": (studyDesignId, visitId, doSchedule) ->
    check visitId, String
    check studyDesignId, String
    n = StudyDesigns.update
      _id: studyDesignId
      'visits._id': visitId
    ,
      $set:
        'visits.$.recordPhysicalData': doSchedule
    throw new Meteor.Error(500, "scheduleRecordPhysicalDataAtVisit: no StudyDesign with that visit found") unless n > 0

    updateRecordPhysicalData(studyDesignId)
    return


  "moveStudyDesignVisit": (studyDesignId, visitId, up) ->
    check visitId, String
    check studyDesignId, String

    design = StudyDesigns.findOne
      _id: studyDesignId
    throw new Meteor.Error(500, "removeStudyDesignVisit: studyDesign not found") unless design?

    visit = _.find design.visits, (v) ->
      v._id is visitId
    throw new Meteor.Error(500, "removeStudyDesignVisit: visit not found") unless visit?

    move = -1
    move = 1 if !up
    return if visit.index is 0 and move is -1
    return if visit.index+1 >= design.visits.length and move is 1
    StudyDesigns.update
      _id: studyDesignId
      'visits.index': visit.index+move
    ,
      $inc:
        'visits.$.index': -move
    StudyDesigns.update
      _id: studyDesignId
      'visits._id': visitId
    ,
      $inc:
        'visits.$.index': move


  "removeStudyDesignVisit": (studyDesignId, visitId) ->
    check visitId, String
    check studyDesignId, String

    design = StudyDesigns.findOne
      _id: studyDesignId
    throw new Meteor.Error(500, "removeStudyDesignVisit: studyDesign not found") unless design?

    visit = _.find design.visits, (v) ->
      v._id is visitId
    throw new Meteor.Error(500, "removeStudyDesignVisit: visit not found") unless visit?

    StudyDesigns.update
      _id: studyDesignId
    ,
      $pull: {visits: {_id: visitId}}

    #TODO normalize visits into it's own collection
    #to avoid stuff like this
    index = visit.index+1
    loop
      n = StudyDesigns.update
        _id: studyDesignId
        'visits.index': index
      ,
        $inc: {'visits.$.index': -1}
      index += 1
      break if n is 0

    updateQuestionnaireIds(studyDesignId)
    updateRecordPhysicalData(studyDesignId)
    return

  
updateQuestionnaireIds = (studyDesignId) ->
  design = StudyDesigns.findOne studyDesignId
  throw new Meteor.Error(500, "updateQuestionnaireIds: studyDesign not found") unless design?
  questionnaireIds = []
  design.visits.forEach (visit) ->
    if visit.questionnaireIds? and visit.questionnaireIds.length > 0
      questionnaireIds = _.union questionnaireIds, visit.questionnaireIds
  StudyDesigns.update
    _id: studyDesignId
  ,
    $set:
      questionnaireIds: questionnaireIds

updateRecordPhysicalData = (studyDesignId) ->
  design = StudyDesigns.findOne studyDesignId
  throw new Meteor.Error(500, "updateRecordPhysicalData: studyDesign not found") unless design?
  recordPhysicalData = false
  _.some design.visits, (visit) ->
    if visit.recordPhysicalData?
      recordPhysicalData = visit.recordPhysicalData
    recordPhysicalData
  StudyDesigns.update
    _id: studyDesignId
  ,
    $set:
      recordPhysicalData: recordPhysicalData
