class @Visit
  constructor: (doc) ->
    _.extend this, doc

  study: ->
    return null unless @studyId?
    Studies.findOne _id: @studyId

  studyDesign: ->
    return null unless @studyDesignId?
    StudyDesigns.findOne _id: @studyDesignId

  isRunning: ->
    @startedAt? and !@endedAt?
  isScheduled: ->
    !@startedAt? and !@endedAt?
  isFinished: ->
    @startedAt? and @endedAt?

  statusText: ->
    if @isFinished()
      "#{fullDateTime(@startedAt)} - #{fullDateTime(@endedAt)}"
    else if @isRunning()
      "running since #{fullDateTime(@startedAt)}"
    else if @isScheduled()
      "scheduled"

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
  startVisit: (visitId) ->
    check(visitId, String)
    visit = Visits.findOne visitId
    throw new Meteor.Error(403, "visit can't be found.") unless visit?

    patient = Patients.findOne
      _id:  visit.patientId
    throw new Meteor.Error(403, "patient can't be found.") unless patient?
    throw new Meteor.Error(433, "you are not allowed to upsert answers") unless Roles.userIsInRole(@userId, ['admin']) or (Roles.userIsInRole(@userId, 'therapist') and patient.therapistId is @userId)
    
    throw new Meteor.Error(403, "another visit is already running for this patient") if patient.runningVisitId?

    Visits.update visit._id,
      $set:
        startedAt: Date.now()
        startedBy: Meteor.userId()
    Patients.update patient._id,
      $set:
        runningVisitId: visit._id
    
  stopVisit: (visitId) ->
    check(visitId, String)
    visit = Visits.findOne visitId
    throw new Meteor.Error(403, "visit can't be found.") unless visit?

    patient = Patients.findOne
      _id:  visit.patientId
    throw new Meteor.Error(403, "patient can't be found.") unless patient?
    throw new Meteor.Error(433, "you are not allowed to upsert answers") unless Roles.userIsInRole(@userId, ['admin']) or (Roles.userIsInRole(@userId, 'therapist') and patient.therapistId is @userId)
    
    if !patient.runningVisitId? or patient.runningVisitId isnt visit._id
      throw new Meteor.Error(403, "this visit isn't running") if patient.runningVisitId?

    Visits.update visit._id,
      $set:
        endedAt: Date.now()
        endedBy: Meteor.userId()
    Patients.update patient._id,
      $unset:
        runningVisitId: visit._id
