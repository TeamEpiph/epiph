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
      questionnaires[q._id] = q
    qIds.forEach (qId) ->
      sortedQuestionnaires.push questionnaires[qId]
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
      quest.answered = true
      quest.numAnswered = 0
      questions = Questions.find
        questionnaireId: quest._id
        type: {$ne: "description"} #filter out descriptions
      .map (question) ->
        if question.subquestions?
          numQuestions += question.subquestions.length
        else
          numQuestions += 1

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
        else if answered
          quest.numAnswered += 1

        question
      #quest.questions = questions
      quest.numQuestions = numQuestions
      quest.answered = false if questions.length is 0
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
  'recordPhysicalData':
    type: Boolean
  'index':
    type: Number
  'day':
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
    throw new Meteor.Error(433, "you are not allowed to upsert answers") unless Roles.userIsInRole(@userId, ['admin']) or (Roles.userIsInRole(@userId, 'therapist') and patient.therapistId is @userId)

    # use query from Patient
    studyDesign = patient.studyDesign()
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
      day: visitTemplate.day if visitTemplate.day?

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
    throw new Meteor.Error(433, "you are not allowed change this visit") unless Roles.userIsInRole(@userId, ['admin']) or (Roles.userIsInRole(@userId, 'therapist') and patient.therapistId is @userId)

    if date?
      Visits.update visitId,
        $set: date: date
    else
      Visits.update visitId,
        $unset: date: ''
    return
