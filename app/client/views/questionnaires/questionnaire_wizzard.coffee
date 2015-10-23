questionIndex = new ReactiveVar(0)

AutoForm.hooks
  questionForm:
    onSubmit: (insertDoc, updateDoc, currentDoc) ->
      insertDoc.visitId = currentDoc.visitId 
      insertDoc.questionId = currentDoc.questionId
      insertDoc._id = currentDoc._id if currentDoc._id? 
      unless currentDoc.value? and currentDoc.value is insertDoc.value
        Meteor.call "upsertAnswer", insertDoc, (error) ->
          throwError error if error?

      questionIndex.set questionIndex.get()+1
      @done()
      false

Template.questionnaireWizzard.created = ->
  @subscribe("questionsForQuestionnaire", @data.questionnaire._id)
  questionIndex.set 1

Template.questionnaireWizzard.helpers
  question: ->
    q = Questions.findOne
      questionnaireId: @questionnaire._id
      index: questionIndex.get()
    TemplateVar.set("questionId", q._id)
    q

  answer: ->
    Answers.findOne
      visitId: @visit._id
      questionId: TemplateVar.get("questionId")

  answerFormSchema: ->
    return null unless @question?
    schema = 
      _id:
        type: String
        optional: true
      visitId:
        type: String
        optional: true
      questionId:
        type: String
        optional: true
      value: @question.getSchemaDict()
    new SimpleSchema(schema)
    
  doc: ->
    @answer or 
      visitId: @visit._id
      questionId: TemplateVar.get("questionId")

  allQuestions: ->
    answers = {}
    questionIds = Questions.find
      questionnaireId: @questionnaire._id
    .map (question) ->
      question._id
    Answers.find
      visitId: @visit._id
      questionId: {$in: questionIds}
    .forEach (answer) ->
      answers[answer.questionId] = answer
    activeIndex = questionIndex.get()
    Questions.find
      questionnaireId: @questionnaire._id
    ,
      sort: {index: 1}
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
    false

  "click .jumpToQuestion": (evt) ->
    questionIndex.set @index
    false
    
  "submit #questionTableForm": (evt) ->
    evt.preventDefault()
    evt.stopPropagation()
    answer = 
      visitId: @visit._id
      questionId: @question._id
      value: []
      _id: @answer._id if @answer?
    for subquestion, i in @question.subquestions
      inputs = $("#questionTableForm input[data-subquestion_index=#{i}]:checked")
      choiceValues=[]
      inputs.each ->
        input = $(@)
        choiceValue = input.data('choice_value')
        choiceValues.push choiceValue
      if choiceValues.length > 0
        answer.value.push 
          subquestionIndex: i
          choiceValues: choiceValues
    console.log answer
    Meteor.call "upsertAnswer", answer, (error) ->
      throwError error if error?
      questionIndex.set questionIndex.get()+1
    false
