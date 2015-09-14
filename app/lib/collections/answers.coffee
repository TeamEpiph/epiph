class @Answer
  constructor: (doc) ->
    _.extend this, doc

@Answers = new Meteor.Collection("answers",
  transform: (doc) ->
    new Answer(doc)
)

Answers.before.insert BeforeInsertTimestampHook
Answers.before.update BeforeUpdateTimestampHook

Answers.allow
  insert: (userId, doc) ->
    false
  update: (userId, doc, fieldNames, modifier) ->
    false
  remove: (userId, doc) ->
    false

Meteor.methods
  "upsertAnswer": (answer) ->
    check(answer.visitId, String)
    visit = Visits.findOne
      _id:  answer.visitId
    throw new Meteor.Error(403, "visit can't be found.") unless visit?

    check(answer.patientId, String)
    patient = Patients.findOne
      _id:  answer.patientId
    throw new Meteor.Error(403, "patient can't be found.") unless patient?
    throw new Meteor.Error(403, "patientId doesn't match visit.patientId") unless visit.patientId is patient._id
    throw new Meteor.Error(433, "you are not allowed to upsert answers") unless Roles.userIsInRole(@userId, ['admin']) or (Roles.userIsInRole(@userId, 'therapist') and patient.therapistId is @userId)

    check(answer.questionnaireId, String)
    questionnaire = Questionnaires.findOne
      _id:  answer.questionnaireId
    throw new Meteor.Error(403, "questionnaire can't be found.") unless questionnaire?
    #TODO check if questionnaire is scheduled at visit

    check(answer.questionId, String)
    question = Questions.findOne
      _id:  answer.questionId
    throw new Meteor.Error(403, "question can't be found.") unless question?
    throw new Meteor.Error(403, "question doesn't belong to questionnaire") unless question.questionnaireId is questionnaire._id

    if answer._id?
      a = Answers.findOne _.pick answer, 'questionnaireId', 'patientId', 'visitId', 'questionId', '_id'
      throw new Meteor.Error(403, "answer to update can't be found.") unless answer?
      
      Answers.update answer._id,
        $set:
          answer: answer.answer
      answer._id
    else
      answer = _.pick answer, 'questionnaireId', 'patientId', 'visitId', 'questionId', 'answer'
      _id = Answers.insert answer
      _id
