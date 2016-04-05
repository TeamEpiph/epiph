_numQuestions = new ReactiveVar(0)
_numPages = new ReactiveVar(0)
_questionIdsForPage = new ReactiveVar({})
_pageIndex = new ReactiveVar(0)
_numFormsToSubmit = 0
_readonly = new ReactiveVar(false)
_questionnaire = new ReactiveVar(null)
_nextQuestionnaire = null
_preview = new ReactiveVar(false)

isAFormDirty = ->
  if _readonly.get() or _preview.get()
    return false
  isDirty = false
  $("form").each () ->
    return if isDirty
    e = $(@)[0]
    dirty = formIsDirty(e)
    isDirty = dirty if dirty
  isDirty


_goto = null
submitAllForms = (goto) ->
  if _readonly.get() or _preview.get()
    throw new Error("Can't submitAllForms because _readonly == true")
  _goto = goto
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
    if _goto is 'nextPage'
      nextPage()
    else if _goto is 'previousPage'
      previousPage()
    else if _goto is 'close'
      Modal.hide('questionnaireWizzard')
    else if _goto.pageIndex?
      _pageIndex.set _goto.pageIndex


close = ->
  if isAFormDirty()
    swal {
      title: 'Unsaved Changes'
      text: "Do you want to save the changes on this page?"
      type: 'warning'
      showCancelButton: true
      confirmButtonText: 'Save and exit'
      cancelButtonText: "Exit without saving"
    }, (save) ->
      if save
        submitAllForms('close')
      else
        Modal.hide('questionnaireWizzard')
  else
    Modal.hide('questionnaireWizzard')


nextPage = ->
  if _pageIndex.get() is _numPages.get()-1
    if _nextQuestionnaire?
      _pageIndex.set 0
      _questionnaire.set _nextQuestionnaire
    else
      Modal.hide('questionnaireWizzard')
  else
    _pageIndex.set _pageIndex.get()+1

previousPage = ->
  index = _pageIndex.get()
  index -= 1 if index > 0
  _pageIndex.set index


autoformHooks = 
  onSubmit: (insertDoc, updateDoc, currentDoc) ->
    return if _preview.get()
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
  _questionnaire.set @data.questionnaire
  delete @data.questionnaire

  if @data.readonly
    _readonly.set true
  else
    _readonly.set false

  if @data.preview
    _preview.set true
  else
    _preview.set false
 
  #close on escape key press
  $(document).on('keyup.wizzard', (e)->
    e.stopPropagation()
    if e.keyCode is 27
      close()
    return
  )

  self = @
  @autorun ->
    self.subscribe("questionsForQuestionnaire", _questionnaire.get()._id)

  #get manage nextQuestionnaire
  @autorun ->
    return if _preview.get()
    data = Template.currentData()
    validatedQuestionnaires = data.visit.validatedQuestionnaires
    i = 0
    index = null
    while i < validatedQuestionnaires.length-1 && index is null
      q = validatedQuestionnaires[i]
      if q._id is _questionnaire.get()._id
        index = i
      i += 1
    if index? and index < validatedQuestionnaires.length-1
      _nextQuestionnaire = validatedQuestionnaires[index+1]
    else
      _nextQuestionnaire = null
  
  #collect autoformIds, count pages
  @autorun ->
    count = 0
    page = 0
    questionIdsForPage = {}
    didBreakPage = false
    autoformIds = []
    Questions.find
      questionnaireId: _questionnaire.get()._id
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

Template.questionnaireWizzard.destroyed = ->
  $(document).unbind('keyup.wizzard')


Template.questionnaireWizzard.helpers
  templateGestures:
    'swipeleft div': (evt, templateInstance) ->
      nextQuestion()

    'swiperight div': (evt, templateInstance) ->
      previousQuestion()

  title: ->
    _questionnaire.get().title

  questionsForPage: ->
    questionIdsForPage = _questionIdsForPage.get()[_pageIndex.get()]
    Questions.find
      questionnaireId: _questionnaire.get()._id
      _id: {$in: questionIdsForPage}
    ,
      sort: {index: 1}

  questionnaire: ->
    _questionnaire.get()

  answerForQuestion: (visitId, questionId) ->
    return if _preview.get()
    Answers.findOne
      visitId: visitId
      questionId: questionId

  readonly: ->
    _readonly.get()

  formType: ->
    if _readonly.get()
      "disabled"
    else
      "normal"

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
    return if _preview.get()
    @answer or 
      visitId: @visit._id
      questionId: @question._id

  pages: ->
    answers = {}
    questionIds = Questions.find
      questionnaireId: _questionnaire.get()._id
    .map (question) ->
      question._id
    if !_preview.get()
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
        questionnaireId: _questionnaire.get()._id
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
        
  isOnFirstPage: ->
    _pageIndex.get() is 0

  isOnLastPageOfLastQuestionnaire: ->
    _pageIndex.get() is _numPages.get()-1 and (_preview.get() or _nextQuestionnaire is null)


Template.questionnaireWizzard.events
  "click #next": (evt, tmpl) ->
    if _readonly.get() or _preview.get()
      nextPage()
    else
      submitAllForms('nextPage')
    false

  "click #back": (evt, tmpl) ->
    if _readonly.get() or _preview.get()
      previousPage()
    else
      submitAllForms('previousPage')
    false

  "click .jumpToPage": (evt) ->
    pageIndex = @index-1
    if isAFormDirty()
      swal {
        title: 'Unsaved Changes'
        text: "Do you want to save the changes on this page?"
        type: 'warning'
        showCancelButton: true
        confirmButtonText: 'Save'
        cancelButtonText: "Don't save"
      }, (save) ->
        if save
          submitAllForms(pageIndex: pageIndex)
        else
          _pageIndex.set pageIndex
    else
      _pageIndex.set pageIndex
    false

  "click #close": (evt) ->
    close()
    false

  "submit .questionForm": (evt) ->
    if _readonly.get() or _preview.get()
      return
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
