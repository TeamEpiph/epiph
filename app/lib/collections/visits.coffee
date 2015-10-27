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
    qs = Questionnaires.find
      _id: {$in: qIds}
    qs

  physioRecords: ->
    PhysioRecords.find
      'metadata.visitId': @_id

  validatedDoc: ->
    valid = true

    physioValid = true
    if @recordPhysicalData? and @physioRecords().count() is 0
      valid = false
      physioValid = false
    @physioValid = physioValid

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
      quest.answered = true
      quest.numAnswered = 0
      questions = Questions.find
        questionnaireId: quest._id
      .map (question) ->
        answers = Answers.find
          visitId: visit._id
          questionId: question._id
        .fetch()
        question.answered = answers.length > 0 or question.type is "markdown"
        question.answers = answers 
        if question.answered 
          quest.numAnswered += 1
        else
          quest.answered = false
        question
      quest.questions = questions
      quest.numQuestions = questions.length
      quest.answered = false if questions.length is 0
      quest
    quests


@Visits = new Meteor.Collection("visits",
  transform: (doc) ->
    new Visit(doc)
)

Visits.before.insert BeforeInsertTimestampHook
Visits.before.update BeforeUpdateTimestampHook

Meteor.methods
  "initVisit": (designVisitId, patientId) ->
    check designVisitId, String
    check patientId, String

    patient = Patients.findOne
      _id:  patientId
    throw new Meteor.Error(403, "patient can't be found.") unless patient?
    throw new Meteor.Error(433, "you are not allowed to upsert answers") unless Roles.userIsInRole(@userId, ['admin']) or (Roles.userIsInRole(@userId, 'therapist') and patient.therapistId is @userId)

    # use query from Patient
    studyDesign = patient.studyDesign()
    throw new Meteor.Error(403, "studyDesign can't be found.") unless studyDesign?

    visitTemplate = _.find studyDesign.visits, (visit) ->
      return visit if visit._id is designVisitId
      false
    throw new Meteor.Error(403, "studyDesign visit can't be found.") unless visitTemplate?

    #we copy the data here from the visit template to
    #an actuall existing visit here
    visit = 
      patientId: patient._id
      designVisitId: visitTemplate._id
      title: visitTemplate.title
      questionnaireIds: visitTemplate.questionnaireIds
      recordPhysicalData: visitTemplate.recordPhysicalData

    _id = Visits.insert visit
    _id
