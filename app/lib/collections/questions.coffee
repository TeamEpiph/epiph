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
    questionnaire = Questionnaires.findOne
      _id: doc.questionnaireId
    questionnaire.creatorId is userId
  update: (userId, doc, fieldNames, modifier) ->
    questionnaire = Questionnaires.findOne
      _id: doc.questionnaireId
    questionnaire.creatorId is userId
  remove: (userId, doc) ->
    questionnaire = Questionnaires.findOne
      _id: doc.questionnaireId
    questionnaire.creatorId is userId

Meteor.methods
  "insertQuestion": (question) ->
    check(question.questionnaireId, String)
    questionnaire = Questionnaires.findOne
      _id:  question.questionnaireId
    throw new Meteor.Error(403, "Only the creator of the questionnaire is allowed to edit it's questions.") unless questionnaire.creatorId is Meteor.userId()

    check(question.label, String)
    check(question.type, String)

    numQuestions = Questions.find
      questionnaireId: @_id
    .count()
    nextIndex = numQuestions-1
    nextIndex = 0 if nextIndex < 0
    if (question.index? and question.index > nextIndex) or !question.index?
      question.index = nextIndex 

    #TODO filter question atters
    _id = Questions.insert question
    _id

  "removeQuestion": (_id) ->
    check(_id, String)
    question = Questions.findOne _id
    questionnaire = Questionnaires.findOne
      _id:  question.questionnaireId
    throw new Meteor.Error(403, "Only the creator of the questionnaire is allowed to edit it's questions.") unless questionnaire.creatorId is Meteor.userId()

    Questions.remove _id
