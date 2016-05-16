@Answers = new Meteor.Collection("answers")

Answers.before.insert BeforeInsertTimestampHook
Answers.before.update BeforeUpdateTimestampHook

Meteor.methods
  "upsertAnswer": (answer) ->
    check(answer.visitId, String)
    visit = Visits.findOne answer.visitId
    throw new Meteor.Error(403, "visit can't be found.") unless visit?

    patient = Patients.findOne visit.patientId
    throw new Meteor.Error(403, "patient can't be found.") unless patient?
    throw new Meteor.Error(433, "you are not allowed to upsert answers") unless Roles.userIsInRole(@userId, ['admin']) or (Roles.userIsInRole(@userId, 'caseManager') and patient.caseManagerId is @userId)

    check(answer.questionId, String)
    question = Questions.findOne  answer.questionId
    throw new Meteor.Error(403, "question can't be found.") unless question?

    questionnaire = Questionnaires.findOne question.questionnaireId
    throw new Meteor.Error(403, "questionnaire can't be found.") unless questionnaire?
    #check if questionnaire is scheduled at visit
    found = false
    visit.questionnaireIds.some (questionnaireId) ->
      if questionnaireId is questionnaire._id
        found = true
      found
    throw new Meteor.Error(403, "questionnaire is not scheduled at this visit.") unless found


    answerId = null
    if answer._id?
      a = Answers.findOne _.pick answer, 'visitId', 'questionId', '_id'
      throw new Meteor.Error(403, "answer to update can't be found.") unless answer?
      
      Answers.update answer._id,
        $set: value: answer.value
      answerId = answer._id
    else
      #check if an answer exists already
      a = Answers.findOne _.pick(answer, 'visitId', 'questionId')
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
      Meteor.call "changeVisitDate", visit._id, Date.now()

    return answerId
