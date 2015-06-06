class @Question
  constructor: (doc) ->
    _.extend this, doc

@Questions = new Meteor.Collection("questions",
  transform: (doc) ->
    new Question(doc)
)

Questions.before.insert BeforeInsertTimestampHook
Questions.before.update BeforeUpdateTimestampHook

Questions.allow
  insert: (userId, doc) ->
    console.log doc
    questionnair = Questionnaires.findOne
      _id: doc.questionnaireId
    questionnair.creatorId is userId
  update: (userId, doc, fieldNames, modifier) ->
    questionnair = Questionnaires.findOne
      _id: doc.questionnaireId
    questionnair.creatorId is userId
  remove: (userId, doc) ->
    questionnair = Questionnaires.findOne
      _id: doc.questionnaireId
    questionnair.creatorId is userId
