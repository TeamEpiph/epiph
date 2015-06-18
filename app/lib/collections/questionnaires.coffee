class @Questionnaire
  constructor: (doc) ->
    _.extend this, doc

@Questionnaires = new Meteor.Collection("questionnaires",
  transform: (doc) ->
    new Questionnaire(doc)
)

Questionnaires.before.insert BeforeInsertTimestampHook
Questionnaires.before.update BeforeUpdateTimestampHook

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
