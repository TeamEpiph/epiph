class @Answer
  constructor: (doc) ->
    _.extend this, doc

@Answers = new Meteor.Collection("answers",
  transform: (doc) ->
    new Answer(doc)
)

Answers.before.insert BeforeInsertTimestampHook
Answers.before.update BeforeUpdateTimestampHook

Meteor.methods
  "upsertAnswer": (answer) ->
    check(answer.visitId, String)
    visit = Visits.findOne
      _id:  answer.visitId
    throw new Meteor.Error(403, "visit can't be found.") unless visit?

    patient = Patients.findOne
      _id:  visit.patientId
    throw new Meteor.Error(403, "patient can't be found.") unless patient?
    throw new Meteor.Error(433, "you are not allowed to upsert answers") unless Roles.userIsInRole(@userId, ['admin']) or (Roles.userIsInRole(@userId, 'therapist') and patient.therapistId is @userId)

    check(answer.questionId, String)
    question = Questions.findOne
      _id:  answer.questionId
    throw new Meteor.Error(403, "question can't be found.") unless question?

    questionnaire = Questionnaires.findOne
      _id:  question.questionnaireId
    throw new Meteor.Error(403, "questionnaire can't be found.") unless questionnaire?
    #TODO check if questionnaire is scheduled at visit

    answerId = null
    if answer._id?
      a = Answers.findOne _.pick answer, 'visitId', 'questionId', '_id'
      throw new Meteor.Error(403, "answer to update can't be found.") unless answer?
      
      Answers.update answer._id,
        $set:
          value: answer.value
      answerId = answer._id
    else
      #check if an answer exists already
      a = Answers.findOne _.pick answer, 'visitId', 'questionId'
      if a?
        console.log "\n\nError: There already exists an answer for this visitId and questionId."
        console.log a
        throw new Meteor.Error(403, "Error: There already exists an answer for this visitId and questionId.")

      answer = _.pick answer, 'visitId', 'questionId', 'value'
      answerId = Answers.insert answer

    if !patient.hasData
      Patients.update patient._id,
        $set: hasData: true

    if !visit.date?
      Visits.update visit._id,
        $set: date: Date.now()

    return answerId
