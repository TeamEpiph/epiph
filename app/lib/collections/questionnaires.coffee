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
      creatorId: Meteor.userId()
    _id
