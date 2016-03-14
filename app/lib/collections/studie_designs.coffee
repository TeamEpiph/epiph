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

    #update existing visits
    Visits.update
      designVisitId: visitId
    ,
      $set:
        title: title
    ,
      multi: true
    return

  "changeStudyDesignVisitDay": (studyDesignId, visitId, day) ->
    check studyDesignId, String
    check visitId, String
    day = parseInt(day)
    check day, Number
    day = null if isNaN(day)

    n = StudyDesigns.update
      _id: studyDesignId
      'visits._id': visitId
    ,
      $set:
        'visits.$.day': day
    throw new Meteor.Error(500, "changeStudyVisitTitle: no StudyDesign.visit to update found") unless n > 0

    #update existing visits
    Visits.update
      designVisitId: visitId
    ,
      $set:
        day: day
    ,
      multi: true
    return

  "scheduleQuestionnairesAtVisit": (studyDesignId, visitId, questionnaireIds) ->
    check studyDesignId, String
    check visitId, String
    check questionnaireIds, [String]

    n = StudyDesigns.update
      _id: studyDesignId
      'visits._id': visitId
    ,
      $set:
        'visits.$.questionnaireIds': questionnaireIds
    throw new Meteor.Error(500, "scheduleQuestionnaireAtVisit: no StudyDesign with that visit found") unless n > 0

    updateQuestionnaireIdsOfStudyDesign(studyDesignId)

    #update existing visits
    Visits.find
      designVisitId: visitId
    .forEach (visit) ->
      addedQuestionnaireIds = _.difference questionnaireIds, visit.questionnaireIds
      if addedQuestionnaireIds.length > 0
        #console.log "pushing:"
        #console.log addedQuestionnaireIds
        Visits.update visit._id,
          $pushAll:
            questionnaireIds: addedQuestionnaireIds

      removedQuestionnaireIds = _.difference visit.questionnaireIds, questionnaireIds
      removeQuestionnaireIds = removedQuestionnaireIds.filter (rQuestId) ->
        rQuestionIds = Questions.find
          questionnaireId: rQuestId
        .map( (q) -> q._id )
        c = Answers.find
          visitId: visit._id
          questionId: {$in: rQuestionIds}
        .count()
        if c > 0
          return false
        return true
      if removeQuestionnaireIds.length > 0
        #console.log "pulling:"
        #console.log removeQuestionnaireIds
        Visits.update visit._id,
          $pullAll:
            questionnaireIds: removeQuestionnaireIds
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

    updateRecordPhysicalDataOfStudyDesign(studyDesignId)

    #update existing visits
    Visits.find
      designVisitId: visitId
    .forEach (visit) ->
      if doSchedule
        Visits.update visit._id,
          $set:
            recordPhysicalData: true
      else
        Visits.update visit._id,
          $set:
            recordPhysicalData: false
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

    #update existing visits
    designVisitIds = design.visits.map (designVisit) ->
      designVisit._id
    Visits.update
      designVisitId: { $in: designVisitIds }
      index: visit.index+move
    ,
      $inc:
        index: -move
    ,
      multi: true
    Visits.update
      designVisitId: visitId
    ,
      $inc:
        index: move
    ,
      multi: true
    return

  "removeStudyDesignVisit": (studyDesignId, visitId) ->
    check visitId, String
    check studyDesignId, String

    design = StudyDesigns.findOne
      _id: studyDesignId
    throw new Meteor.Error(500, "removeStudyDesignVisit: studyDesign not found") unless design?

    visit = _.find design.visits, (v) ->
      v._id is visitId
    throw new Meteor.Error(500, "removeStudyDesignVisit: visit not found") unless visit?

    #check existing visits
    visits = Visits.find
      designVisitId: visitId
    .fetch()
    foundData = _.some visits, (visit) ->
      questionIds = Questions.find
        questionnaireId:
          $in: visit.questionnaireIds
      .map( (q) -> q._id )
      c1 = Answers.find
        visitId: visit._id
        questionId: {$in: questionIds}
      .count()
      if c1 > 0
        console.log "the following visit of the template has data attached:"
        console.log visit
        return true
      return false
    throw new Meteor.Error(500, "The visit is used by at least one patient and has data attached to it. Please consult your system operator for further information.") if foundData
 
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

    updateQuestionnaireIdsOfStudyDesign(studyDesignId)
    updateRecordPhysicalDataOfStudyDesign(studyDesignId)
    return


updateQuestionnaireIdsOfStudyDesign = (studyDesignId) ->
  design = StudyDesigns.findOne studyDesignId
  throw new Meteor.Error(500, "updateQuestionnaireIdsOfStudyDesign: studyDesign not found") unless design?
  questionnaireIds = []
  design.visits.forEach (visit) ->
    if visit.questionnaireIds? and visit.questionnaireIds.length > 0
      questionnaireIds = _.union questionnaireIds, visit.questionnaireIds
  StudyDesigns.update
    _id: studyDesignId
  ,
    $set:
      questionnaireIds: questionnaireIds

updateRecordPhysicalDataOfStudyDesign = (studyDesignId) ->
  design = StudyDesigns.findOne studyDesignId
  throw new Meteor.Error(500, "updateRecordPhysicalDataOfStudyDesign: studyDesign not found") unless design?
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
