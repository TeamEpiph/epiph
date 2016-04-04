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

Questionnaires.allow
  update: (userId, doc, fieldNames, modifier) ->
    #TODO check if allowed
    notAllowedFields = _.without fieldNames, 'title', 'id', 'updatedAt'
    return false if notAllowedFields.length > 0
    true

Meteor.methods
  "createQuestionnaire": (title) ->
    _id = Questionnaires.insert
      title: "new Questionnaire"
      creatorId: Meteor.userId()
    _id

  "copyQuestionnaire": (questionnaireId) ->
    console.log "copyQuestionnaire"
    questionnaire = Questionnaires.findOne questionnaireId
    throw new Meteor.Error(403, "questionnaire not found.") unless questionnaire?

    delete questionnaire._id
    delete questionnaire.createdAt
    questionnaire.title += " copy"
    qId = Questionnaires.insert questionnaire

    Questions.find(
      questionnaireId: questionnaireId
    ).forEach (q) ->
      delete q._id
      delete q.createdAt
      q.questionnaireId = qId
      Questions.insert q
    return

  "removeQuestionnaire": (_id) ->
    #TODO: check if studies are affected
    Questionnaires.remove
      _id: _id
    Questions.remove
      questionnaireId: _id
