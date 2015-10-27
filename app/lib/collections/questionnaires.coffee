class @Questionnaire
  constructor: (doc) ->
    _.extend this, doc

  creator: ->
    Meteor.users.findOne _id: @creatorId

  editingNotAllowed: ->
    false

@Questionnaires = new Meteor.Collection("questionnaires",
  transform: (doc) ->
    new Questionnaire(doc)
)

Questionnaires.before.insert BeforeInsertTimestampHook
Questionnaires.before.update BeforeUpdateTimestampHook

Questionnaires.allow
  update: (userId, doc, fieldNames, modifier) ->
    #TODO check if allowed
    notAllowedFields = _.without fieldNames, 'title', 'key', 'updatedAt'
    return false if notAllowedFields.length > 0
    true

Meteor.methods
  "createQuestionnaire": (title) ->
    _id = Questionnaires.insert
      title: "new Questionnaire"
      creatorId: Meteor.userId()
    _id

  "removeQuestionnaire": (_id) ->
    #TODO: check if studies are affected
    Questionnaires.remove
      _id: _id
    Questions.remove
      questionnaireId: _id
