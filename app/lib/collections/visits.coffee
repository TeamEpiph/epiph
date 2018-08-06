class @Visit
  constructor: (doc) ->
    _.extend this, doc

  study: ->
    return null unless @studyId?
    Studies.findOne _id: @studyId

  studyDesign: ->
    return null unless @studyDesignId?
    StudyDesigns.findOne _id: @studyDesignId

  questionnaires: ->
    qIds = @questionnaireIds or []
    questionnaires = {}
    sortedQuestionnaires = []
    Questionnaires.find(
      _id: {$in: qIds}
    ).forEach (q) ->
      if q?
        questionnaires[q._id] = q
    qIds.forEach (qId) ->
      questionnaire = questionnaires[qId]
      if questionnaire?
        sortedQuestionnaires.push questionnaire
    sortedQuestionnaires

  validatedDoc: ->
    valid = true

    #we can't check, so assume true
    @physioValid = true

    validatedQuestionnaires = @getValidatedQuestionnaires()
    if valid
      _.some validatedQuestionnaires, (quest) ->
        if quest.answered is false
          valid = false
        !valid
    @validatedQuestionnaires = validatedQuestionnaires
    @valid = valid
    @

  getValidatedQuestionnaires: ->
    visit = @
    quests = @questionnaires().map (quest) ->
      numQuestions = 0
      numQuestionsRequired = 0
      quest.answered = true
      quest.numAnswered = 0
      quest.numAnsweredRequired = 0
      questions = Questions.find
        questionnaireId: quest._id
        type: {$ne: "description"} #filter out descriptions
      .map (question) ->
        if question.subquestions?
          numQuestions += question.subquestions.length
          if !question.optional
            numQuestionsRequired += question.subquestions.length
        else
          numQuestions += 1
          if !question.optional
            numQuestionsRequired++

        answer = Answers.findOne
          visitId: visit._id
          questionId: question._id

        answered = answer?
        if question.type is 'table' or question.type is 'table_polar'
          answered = answer? and answer.value.length is question.subquestions.length
        #question.answered = answered

        if !answered
          quest.answered = false

        if question.subquestions?
          if answer?
            quest.numAnswered += answer.value.length
            if !question.optional
              quest.numAnsweredRequired += answer.value.length
        else if answered
          quest.numAnswered += 1
          if !question.optional
            quest.numAnsweredRequired++

        question
      #quest.questions = questions
      quest.numQuestions = numQuestions
      quest.numQuestionsRequired = numQuestionsRequired
      quest.answered = true if quest.numAnsweredRequired >= quest.numQuestionsRequired
      quest
    quests


@Visits = new Meteor.Collection("visits",
  transform: (doc) ->
    new Visit(doc)
)

Visits.before.insert BeforeInsertTimestampHook
Visits.before.update BeforeUpdateTimestampHook

schema =
  'patientId':
    type: String
  'designVisitId':
    type: String
  'title':
    type: String
  'questionnaireIds':
    type: [String]
    defaultValue: []
  'recordPhysicalData':
    type: Boolean
    defaultValue: false
  'index':
    type: Number
  'daysOffsetFromPrevious':
    type: Number
    optional: true
  'daysOffsetFromBaseline':
    type: Number
    optional: true
  'date':
    type: Number
    optional: true
  'updatedAt':
    type: Number
    optional: true
  'createdAt':
    type: Number
    optional: true
Visits.attachSchema new SimpleSchema(schema)

Meteor.methods
  "initVisit": (designVisitId, patientId) ->
    check designVisitId, String
    check patientId, String

    patient = Patients.findOne patientId
    throw new Meteor.Error(403, "patient can't be found.") unless patient?
    throw new Meteor.Error(433, "you are not allowed to upsert answers") unless Roles.userIsInRole(@userId, ['admin']) or (Roles.userIsInRole(@userId, 'caseManager') and  @userId in patient.caseManagerIds)

    # use query from Patient
    studyDesign = StudyDesigns.findOne
      _id: $in: patient.studyDesignIds
      'visits._id': designVisitId
    throw new Meteor.Error(403, "studyDesign can't be found.") unless studyDesign?

    visitTemplate = _.find studyDesign.visits, (visit) ->
      return visit if visit._id is designVisitId
      false
    throw new Meteor.Error(403, "studyDesign visit can't be found.") unless visitTemplate?

    #check if visit does not exist already
    c = Visits.find
      patientId: patient._id
      designVisitId: visitTemplate._id
    .count()
    #happens on reload, shouldn't be a problem to ignore
    return if c > 0
    #throw new Meteor.Error(403, "a visit from this template exists aready for the patient") if c > 0

    #we copy the data here from the visit template to
    #an actuall existing visit here
    visit =
      patientId: patient._id
      designVisitId: visitTemplate._id
      title: visitTemplate.title
      questionnaireIds: visitTemplate.questionnaireIds
      recordPhysicalData: visitTemplate.recordPhysicalData
      index: visitTemplate.index
      daysOffsetFromPrevious: visitTemplate.daysOffsetFromPrevious if visitTemplate.daysOffsetFromPrevious?
      daysOffsetFromBaseline: visitTemplate.daysOffsetFromBaseline if visitTemplate.daysOffsetFromBaseline?

    _id = Visits.insert visit
    _id


  "changeVisitDate": (visitId, date) ->
    check visitId, String
    if date? #we allow null values
      check date, Number
      check isNaN(date), false

    visit = Visits.findOne visitId
    throw new Meteor.Error(403, "visit can't be found.") unless visit?

    patient = Patients.findOne visit.patientId
    throw new Meteor.Error(403, "patient can't be found.") unless patient?
    throw new Meteor.Error(433, "you are not allowed change this visit") unless Roles.userIsInRole(@userId, ['admin']) or (Roles.userIsInRole(@userId, 'caseManager') and @userId in patient.caseManagerIds)

    if date?
      Visits.update visitId,
        $set: date: date
    else
      Visits.update visitId,
        $unset: date: ''
    return

  "removeAnswersOfQuestionnaireFromVisit": (visitId, questionnaireId, reason) ->
    checkIfAdmin()
    check(visitId, String)
    check(questionnaireId, String)
    check(reason, String)

    questionnaire = Questionnaires.findOne questionnaireId
    throw new Meteor.Error(403, "questionnaire not found.") unless questionnaire?
    visit = Visits.findOne visitId
    throw new Meteor.Error(403, "visit not found.") unless visit?
    patient = Patients.findOne visit.patientId
    throw new Meteor.Error(403, "patient not found.") unless patient?

    questionIds = Questions.find({questionnaireId: questionnaireId}).map (q) ->
      q._id
    answers = Answers.find(
      questionId: $in: questionIds
      visitId: visitId
    ).fetch()

    Meteor.call "logActivity", "remove all answers of questionnaire (#{questionnaire.id} - #{questionnaire.title}) from visit (#{visit.title} - #{visit._id}) from patient (#{patient.hrid} - #{patient.id})", "critical", reason, answers

    answerIds = answers.map (a) -> a._id
    Answers.remove
      _id: $in: answerIds
    return


@__getScheduledVisitsForPatientId = (patientId, studyDesignId) ->
  check patientId, String
  check studyDesignId, String

  patient = Patients.findOne patientId
  throw new Meteor.Error(403, "patient can't be found.") unless patient?

  studyDesign = StudyDesigns.findOne studyDesignId
  if !studyDesign?
    return []

  visits = studyDesign.visits.map (designVisit) ->
    visit = Visits.findOne
      designVisitId: designVisit._id
      patientId: patient._id
    #dummy visit for validation to work
    visit = new Visit(designVisit) if !visit?
    visit.validatedDoc()
  visits.sort (a,b) ->
    a.index - b.index
  previousDate = null
  previousVisit = null
  baselineDate = null
  visits.forEach (v) ->
    if previousDate? and v.daysOffsetFromPrevious?
      v.dateScheduled = moment(previousDate).add(v.daysOffsetFromPrevious, 'days')
    else if baselineDate? and v.daysOffsetFromBaseline?
      v.dateScheduled = moment(baselineDate).add(v.daysOffsetFromBaseline, 'days')

    if !baselineDate? and v.daysOffsetFromBaseline is 0 #this is our baseline
      if v.date?
        baselineDate = moment(v.date)
      #special case for visit before baseline with negative daysOffsetFromBaseline
      #if there are multiple such vists, the one closest to the baseline wins
      if previousDate? and previousVisit? and previousVisit.daysOffsetFromBaseline < 0
        v.dateScheduled = moment(previousDate).add(-previousVisit.daysOffsetFromBaseline, 'days')
        baselineDate = moment(v.dateScheduled)

    if v.date?
      previousDate = moment(v.date)
    else if v.dateScheduled?
      previousDate = moment(v.dateScheduled)
    previousVisit = v
  visits.sort (a, b) ->
    a.index - b.index
  return visits
