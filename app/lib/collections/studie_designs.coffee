class @StudyDesign
  constructor: (doc) ->
    _.extend this, doc

@StudyDesigns = new Meteor.Collection("study_designs",
  transform: (doc) ->
    new StudyDesign(doc)
)

StudyDesigns.before.insert BeforeInsertTimestampHook
StudyDesigns.before.update BeforeUpdateTimestampHook

#FIXME
StudyDesigns.allow
  insert: (userId, doc) ->
    false
  update: (userId, doc, fieldNames, modifier) ->
    true
  remove: (userId, doc) ->
    false 

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
        title: "baseline"
      ]
    _id

  "removeStudyDesign": (_id) ->
    #TODO: check if allowed
    StudyDesigns.remove
      _id: _id

  "addStudyDesignVisit": (studyDesignId, days) ->
    check studyDesignId, String
    days = parseInt(days)
    check days, Number

    design = StudyDesigns.findOne
      _id: studyDesignId
    throw new Meteor.Error(500, "StudyDesign #{studyDesignId} not found!") unless design?

    preVisit = design.visits[design.visits.length-1]
    day = preVisit.day+days
    if preVisit.day is day
      throw new Meteor.Error(500, "A visit on this day already exists") 

    title = "visit #{design.visits.length}"
    if design.visits.length is 0
      title = "baseline"
    visit = 
      _id: new Meteor.Collection.ObjectID()._str
      day: day
      title: title
       
    StudyDesigns.update
      _id: studyDesignId
    ,
      $push:
        visits: visit

  "addMultipleStudyDesignVisits": (params) ->
    check params.studyDesignId, String
    check params.title, String
    check params.key, String
    check params.startDay, Number
    check params.numVisits, Number
    check params.daysBetween, Number

    design = StudyDesigns.findOne
      _id: params.studyDesignId
    throw new Meteor.Error(500, "StudyDesign #{params.studyDesignId} not found!") unless design?

    visits = []
    groupId = new Meteor.Collection.ObjectID()._str
    for i in [0...params.numVisits] 
      title = "#{params.title} #{i+1}"
      key = "#{params.key}-#{i+1}"
      visit = 
        _id: new Meteor.Collection.ObjectID()._str
        groupId: groupId
        day: params.startDay+(i*params.daysBetween)
        title: title
        key: key
      visits.push visit
    
    StudyDesigns.update
      _id: design._id
    ,
      $pushAll:
        visits: visits

      
  "scheduleQuestionnaireAtVisit": (studyDesignId, visitId, questionnaireId, doSchedule, doAllOfGroup) ->
    check visitId, String
    check questionnaireId, String
    if doSchedule
      n = 0
      n = StudyDesigns.update
        _id: studyDesignId
      ,
        $push: 
          questionnaireIds: questionnaireId
      throw new Meteor.Error(500, "mapQuestionnaireToVisit: no StudyDesign found") unless n > 0
    n = 0
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
    throw new Meteor.Error(500, "mapQuestionnaireToVisit: no StudyDesign with that visit found") unless n > 0

  "scheduleRecordPhysicalDataAtVisit": (studyDesignId, visitId, doSchedule) ->
    check visitId, String
    check studyDesignId, String
    n = StudyDesigns.update
      _id: studyDesignId
      'visits._id': visitId
    ,
      $set: 
        'visits.$.recordPhysicalData': doSchedule
    throw new Meteor.Error(500, "recordPhysicalDataAtVisit: no StudyDesign with that visit found") unless n > 0
