questionIndex = new ReactiveVar(0)

AutoForm.hooks
  questionForm:
    onSubmit: (insertDoc, updateDoc, currentDoc) ->
      insertDoc.patientId = currentDoc.patientId 
      insertDoc.visitId = currentDoc.visitId 
      insertDoc.questionId = currentDoc.questionId
      insertDoc.questionnaireId = currentDoc.questionnaireId 
      insertDoc._id = currentDoc._id if currentDoc._id? 
      unless currentDoc.answer? and currentDoc.answer is insertDoc.answer
        Meteor.call "upsertAnswer", insertDoc

      questionIndex.set questionIndex.get()+1
      @done()
      false

Template.questionnaireWizzard.created = ->
  template = @
  @subscribe("questionsForQuestionnaire", @data.questionnaire._id)
  @subscribe("answersForVisitAndQuestionnaire", @data.visit._id, @data.questionnaire._id)
  questionIndex.set 1

Template.questionnaireWizzard.helpers
  questionFormSchema: ->
    q = Questions.findOne(
      questionnaireId: @questionnaire._id
      index: questionIndex.get()
    )
    return null unless q?
    TemplateVar.set("questionId", q._id)
    schema = 
      _id:
        type: String
        optional: true
      patientId:
        type: String
        optional: true
      visitId:
        type: String
        optional: true
      questionnaireId:
        type: String
        optional: true
      questionId:
        type: String
        optional: true
      answer: q.getSchemaDict()
    new SimpleSchema(schema)
    
  doc: ->
    a = Answers.findOne
      patientId: @patient._id
      visitId: @visit._id
      questionnaireId: @questionnaire._id
      questionId: TemplateVar.get("questionId")
    a or 
      patientId: @patient._id
      visitId: @visit._id
      questionnaireId: @questionnaire._id
      questionId: TemplateVar.get("questionId")

  allQuestions: ->
    answers = {}
    Answers.find
      visitId: @visit._id
      questionnaireId: @questionnaire._id
    .forEach (answer) ->
      answers[answer.questionId] = answer
    activeIndex = questionIndex.get()
    Questions.find
      questionnaireId: @questionnaire._id
    .map (question) ->
      if answers[question._id]?
        question.css = "answered"
      if question.index is activeIndex
        question.css += " active"
      question
        

Template.questionnaireWizzard.events
  "click #back": (evt, tmpl) ->
    index = questionIndex.get()
    index = index-1 if index > 0
    questionIndex.set index

  "click .jumpToQuestion": (evt) ->
    questionIndex.set @index
    
