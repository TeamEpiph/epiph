class @Questionnaire
  constructor: (doc) ->
    _.extend this, doc

  creator: ->
    Meteor.users.findOne _id: @creatorId

  editingNotAllowed: ->
    false

  numQuestions: ->
    numQuestions = 0
    Questions.find(
      questionnaireId: @_id
      type: {$ne: "description"}
    ).forEach (question) ->
      if question.subquestions?
        numQuestions += question.subquestions.length
      else
        numQuestions += 1
    numQuestions

  numPages: ->
    numPages = 1
    Questions.find(
      questionnaireId: @_id
    ).forEach (question) ->
      if question.break? and question.break
        numPages += 1
    numPages


@Questionnaires = new Meteor.Collection("questionnaires",
  transform: (doc) ->
    new Questionnaire(doc)
)

Questionnaires.before.insert BeforeInsertTimestampHook
Questionnaires.before.update BeforeUpdateTimestampHook

_schema =
  title:
    type: String
  id:
    label: 'ID'
    type: String
    index: true
    unique: true
Questionnaires.attachSchema(new SimpleSchema(_schema))

Questionnaires.allow
  update: (userId, doc, fieldNames, modifier) ->
    #TODO check if allowed
    notAllowedFields = _.without fieldNames, 'title', 'id', 'updatedAt'
    return false if notAllowedFields.length > 0
    true


Meteor.methods
  createQuestionnaire: (title) ->
    _id = Questionnaires.insert
      title: "new Questionnaire"
      id: __findUnique(Questionnaires, "id", "newq")
      creatorId: Meteor.userId()
    _id

  updateQuestionnaire: (modifier, docId) ->
    #workaround strange unique errors
    #https://github.com/aldeed/meteor-collection2/issues/218
    if (id=modifier['$set'].id)?
      if Questionnaires.find(
        _id: $ne: docId
        id: id
      ).count() > 0
        details = EJSON.stringify [
          name: "id"
          type: "notUnique"
          value: ""
        ]
        throw new Meteor.Error(400, "validationError", details)
    Questionnaires.update docId, modifier

  copyQuestionnaire: (questionnaireId) ->
    questionnaire = Questionnaires.findOne questionnaireId
    throw new Meteor.Error(403, "questionnaire not found.") unless questionnaire?

    delete questionnaire._id
    delete questionnaire.createdAt
    questionnaire.title = __findUnique(Questionnaires, "title", questionnaire.title)
    questionnaire.id = __findUnique(Questionnaires, "id", questionnaire.id)
    qId = Questionnaires.insert questionnaire

    Questions.find(
      questionnaireId: questionnaireId
    ).forEach (q) ->
      delete q._id
      delete q.createdAt
      q.questionnaireId = qId
      Questions.insert q
    return

  removeQuestionnaire: (_id) ->
    #TODO: check if studies are affected
    Questionnaires.remove
      _id: _id
    Questions.remove
      questionnaireId: _id
