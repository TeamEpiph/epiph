_numQuestions = new ReactiveVar(0)
_numPages = new ReactiveVar(0)
_questionIdsForPage = new ReactiveVar({})
_pageIndex = new ReactiveVar(0)
_numFormsToSubmit = 0

nextPage = ->
  if _pageIndex.get() is _numPages.get()-1
    Modal.hide('viewQuestionnaire') 
  else
    _pageIndex.set _pageIndex.get()+1

previousPage = ->
  index = _pageIndex.get()
  index -= 1 if index > 0
  _pageIndex.set index


_gotoNextPage = null
submitAllForms = (gotoNextPage) ->
  _gotoNextPage = gotoNextPage
  numFormsToSubmit = 0
  $("form").each () ->
    e = $(@)
    classes = e.attr('class')
    if classes? and classes.indexOf('question') > -1
      numFormsToSubmit += 1
  _numFormsToSubmit = numFormsToSubmit
  $("form").each () ->
    e = $(@)
    classes = e.attr('class')
    if classes? and classes.indexOf('question') > -1
      e.submit()

formSubmitted = ->
  if (_numFormsToSubmit -= 1) <= 0
    if _gotoNextPage
      nextPage()
    else
      previousPage()


autoformHooks = 
  onSubmit: (insertDoc, updateDoc, currentDoc) ->
    insertDoc.visitId = currentDoc.visitId 
    insertDoc.questionId = currentDoc.questionId
    insertDoc._id = currentDoc._id if currentDoc._id? 
    #console.log "submit questionAutoform"
    #console.log insertDoc
    if insertDoc.value? and (!currentDoc.value? or (currentDoc.value? and currentDoc.value isnt insertDoc.value))
      Meteor.call "upsertAnswer", insertDoc, (error) ->
        throwError error if error?
    formSubmitted()
    @done()
    false


Template.questionnaireWizzard.created = ->
  @subscribe("questionsForQuestionnaire", @data.questionnaire._id)
  self = @
  @autorun ->
    count = 0
    page = 0
    questionIdsForPage = {}
    didBreakPage = false
    autoformIds = []
    Questions.find
      questionnaireId: self.data.questionnaire._id
    ,
      sort: {index: 1}
    .forEach (q) ->
      if q.type isnt "description" and q._id isnt "table" and q._id isnt "table_polar"
        autoformIds.push q._id
      count += 1
      if questionIdsForPage[page]?
        questionIdsForPage[page].push q._id
      else
        questionIdsForPage[page] = [q._id]
      didBreakPage = false
      if q.break
        page += 1
        didBreakPage = true

    page -= 1 if didBreakPage
    _questionIdsForPage.set questionIdsForPage
    _numQuestions.set count
    _numPages.set page+1
    _pageIndex.set 0
    AutoForm.addHooks(autoformIds, autoformHooks)


Template.questionnaireWizzard.helpers
  templateGestures:
    'swipeleft div': (evt, templateInstance) ->
      nextQuestion()

    'swiperight div': (evt, templateInstance) ->
      previousQuestion()

  questionsForPage: ->
    questionIdsForPage = _questionIdsForPage.get()[_pageIndex.get()]
    Questions.find
      questionnaireId: @questionnaire._id
      _id: {$in: questionIdsForPage}
    ,
      sort: {index: 1}

  answerForQuestion: (visitId, questionId) ->
    Answers.findOne
      visitId: visitId
      questionId: questionId

  answerFormSchema: ->
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
      questionId: @question._id

  pages: ->
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
    activeIndex = _pageIndex.get()
    questionIdsForPage = _questionIdsForPage.get()
    pages = []
    for i in [0.._numPages.get()-1]
      css = ""
      allQuestionsAnsweredInPage = true
      someQuestionsAnsweredInPage = false
      Questions.find
        questionnaireId: @questionnaire._id
        _id: {$in: questionIdsForPage[i]}
      .forEach (question) ->
        return if question.type is "description"
        answer = answers[question._id]
        if question.type is "table" or question.type is "table_polar" or question.type is "multipleChoice"
          if !answer? or answer.value.length < question.subquestions.length
            allQuestionsAnsweredInPage = false
          if answer? and answer.value.length > 0
            someQuestionsAnsweredInPage = true
        else if !answer?
          allQuestionsAnsweredInPage = false
      if allQuestionsAnsweredInPage
        css = "answered"
      else if someQuestionsAnsweredInPage
        css = "answeredPartly"
      if i is activeIndex
        css += " active"
      pages[i] = 
        index: i+1
        css: css
    pages
        

Template.questionnaireWizzard.events
  "click #next": (evt, tmpl) ->
    submitAllForms(true)
    false

  "click #back": (evt, tmpl) ->
    submitAllForms(false)
    false

  "click .jumpToPage": (evt) ->
    _pageIndex.set @index-1
    false
    
  "submit .questionForm": (evt) ->
    evt.preventDefault()
    evt.stopPropagation()
    if @question.type is "description"
      formSubmitted()
      return
    answer = 
      visitId: @visit._id
      questionId: @question._id
      value: []
      _id: @answer._id if @answer?
    for subquestion in @question.subquestions
      inputs = $(evt.target).find("input[data-subquestion_code=#{subquestion.code}]:checked")
      checkedChoices=[]
      inputs.each -> #checked choices
        input = $(@)
        checkedChoices.push 
          value: input.data('choice_value').toString()
          variable: input.data('choice_variable').toString()
      if checkedChoices.length > 0
        answer.value.push 
          code: subquestion.code
          checkedChoices: checkedChoices
    if answer.value.length > 0
      Meteor.call "upsertAnswer", answer, (error) ->
        throwError error if error?
        formSubmitted()
    else
      formSubmitted()
    false
