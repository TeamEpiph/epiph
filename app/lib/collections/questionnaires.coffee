class @Questionnaire
  constructor: (doc) ->
    _.extend this, doc

  creator: ->
    Meteor.users.findOne _id: @creatorId

  editingNotAllowed: ->
    false

  numQuestions: ->
    numQuestions = 0
    Questions.find(
      questionnaireId: @_id
      type: {$ne: "description"}
    ).forEach (question) ->
      if question.subquestions?
        numQuestions += question.subquestions.length
      else
        numQuestions += 1
    numQuestions

  numPages: ->
    numPages = 1
    Questions.find(
      questionnaireId: @_id
    ).forEach (question) ->
      if question.break? and question.break
        numPages += 1
    numPages

  languages: ->
    langs = ""
    langs += @primaryLanguage if @primaryLanguage?
    if @translationLanguages? and @translationLanguages.length > 0
      langs += ', '
      langs += @translationLanguages.join ', '
    langs


@Questionnaires = new Meteor.Collection("questionnaires",
  transform: (doc) ->
    new Questionnaire(doc)
)

Questionnaires.before.insert BeforeInsertTimestampHook
Questionnaires.before.update BeforeUpdateTimestampHook

_schema =
  title:
    type: String
  id:
    label: 'ID'
    type: String
    index: true
    unique: true
  primaryLanguage:
    label: 'Primary Language'
    type: String
    optional: true
  translationLanguages:
    type: [String]
    optional: true
Questionnaires.attachSchema(new SimpleSchema(_schema))


Meteor.methods
  createQuestionnaire: ->
    checkIfAdmin()
    _id = Questionnaires.insert
      title: "new Questionnaire"
      id: __findUnique(Questionnaires, "id", "newq")
      creatorId: Meteor.userId()
    _id

  updateQuestionnaire: (modifier, docId, forceReason) ->
    checkIfAdmin()
    check(modifier, Object)
    check(docId, String)

    questionnaire = Questionnaires.findOne docId
    throw new Meteor.Error(403, "questionnaire not found.") unless questionnaire?

    #workaround strange unique errors
    #https://github.com/aldeed/meteor-collection2/issues/218
    if (id=modifier['$set'].id)?
      if Questionnaires.find(
        _id: $ne: docId
        id: id
      ).count() > 0
        details = EJSON.stringify [
          name: "id"
          type: "notUnique"
          value: ""
        ]
        throw new Meteor.Error(400, "validationError", details)

    #check if primaryLanguage is changed to an existing translation
    if ( (newLang=modifier['$set'].primaryLanguage) isnt questionnaire.primaryLanguage)
      if questionnaire.translationLanguages.indexOf(newLang) > -1
        throw new Meteor.Error(400, "Can't set #{newLang} as the primary language for this questionnaire because a translation to this language exists already. If you really wan't to do this, please delete the translation first.")

    #check if questionnaire is used
    questionIds = Questions.find(
      questionnaireId: docId
    ).map (q) ->
      q._id
    count = Answers.find(
      questionId: $in: questionIds
    ).count()
    if count > 0
      if !forceReason
        throw new Meteor.Error(400, "questionnaireIsUsedProvideReason")
      else
        s = modifier['$set']
        Meteor.call "logActivity", "change title/id of questionnaire (#{questionnaire.title} / #{questionnaire.id}) which in use to (#{s.title} / #{s.id})", "notice", forceReason, modifier['$set']
    Questionnaires.update docId, modifier

  copyQuestionnaire: (questionnaireId) ->
    checkIfAdmin()
    check(questionnaireId, String)

    questionnaire = Questionnaires.findOne questionnaireId
    throw new Meteor.Error(403, "questionnaire not found.") unless questionnaire?

    delete questionnaire._id
    delete questionnaire.createdAt
    questionnaire.title = __findUnique(Questionnaires, "title", questionnaire.title)
    questionnaire.id = __findUnique(Questionnaires, "id", questionnaire.id)
    qId = Questionnaires.insert questionnaire

    Questions.find(
      questionnaireId: questionnaireId
    ).forEach (q) ->
      delete q._id
      delete q.createdAt
      q.questionnaireId = qId
      Questions.insert q
    return

  removeQuestionnaire: (questionnaireId) ->
    checkIfAdmin()
    check(questionnaireId, String)

    questionnaire = Questionnaires.findOne questionnaireId
    throw new Meteor.Error(403, "questionnaire not found.") unless questionnaire?

    #check if studies are affected
    studyIds = []
    studyDesignIds = StudyDesigns.find(
      questionnaireIds: questionnaireId
    ).map (sd) -> 
      studyIds.push sd.studyId
      sd._id
    studyIds = _.uniq studyIds
    if studyDesignIds.length > 0
      usedIn = ""
      Studies.find(_id: $in: studyIds).forEach (s) ->
        usedIn += "#{s.title} ("
        StudyDesigns.find(
          _id: $in: studyDesignIds
          studyId: s._id
          questionnaireIds: questionnaireId
        ).forEach (sd) ->
          usedIn += "#{sd.title}, "
        usedIn = "#{usedIn.slice(0, -2)}), "
      usedIn = usedIn.slice(0, -2)
      throw new Meteor.Error(400, "validationErrorQuestionnaireInUse", usedIn)

    Questionnaires.remove
      _id: questionnaireId
    Questions.remove
      questionnaireId: questionnaireId
    return
