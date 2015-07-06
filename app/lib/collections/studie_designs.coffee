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
      ]
    _id

  "removeStudyDesign": (_id) ->
    #TODO: check if allowed
    StudyDesigns.remove
      _id: _id

  "addStudyDesignVisit": (studyDesignId, day) ->
    check studyDesignId, String
    day = parseInt(day)
    check day, Number
    preVisit = StudyDesigns.findOne
      _id: studyDesignId
      visits:
        $elemMatch: { day: { $lte: day } }
    preVisit = preVisit.visits[0]

    if preVisit.day is day
      throw new Meteor.Error(500, "A visit on this day already exists") 

    visit = 
      _id: new Meteor.Collection.ObjectID()._str
      day: day
      index: preVisit.index+1
       
    StudyDesigns.update
      _id: studyDesignId
    ,
      $push:
        visits: visit
      
  "mapQuestionnaireToVisit": (studyDesignId, visitId, questionnaireId) ->
    check visitId, String
    check questionnaireId, String
    n = StudyDesigns.update
      _id: studyDesignId
    ,
      $push: 
        questionnaireIds: questionnaireId
    throw new Meteor.Error(500, "mapQuestionnaireToVisit: no StudyDesign found") unless n > 0
    n = StudyDesigns.update
      _id: studyDesignId
      'visits._id': visitId
    ,
      $push: 
        'visits.$.questionnaireIds': questionnaireId
    throw new Meteor.Error(500, "mapQuestionnaireToVisit: no StudyDesign with that visit found") unless n > 0
