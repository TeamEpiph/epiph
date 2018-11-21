@__showQuestionnaireWizzard = (data) ->
  Session.set 'selectedQuestionnaireWizzard', data
  if !data.readonly
    #check if this questionnaire was answered before by this patient
    #we do this on the client only, because we can't check it properly by the
    #server anyway
    questionIds = Questions.find(
      questionnaireId: data.questionnaire._id
    ).map (q) -> q._id
    count = Answers.find(
      visitId: data.visit._id
      questionId: $in: questionIds
    ).count()
    if count > 0
      swal {
        title: 'Attention!'
        text: "This questionnaire was alredy filled out. To view data, please use the ‘show’ button. Do you want to proceed? Old data will be overwritten. A log entry will be created. Please state a reason."
        type: 'input'
        inputPlaceholder: "Please state a reason."
        showCancelButton: true
        confirmButtonText: 'Yes'
        closeOnConfirm: false
      }, (confirmedWithReason)->
        if confirmedWithReason is false #cancel
          swal.close()
        else
          if !confirmedWithReason? or confirmedWithReason.length is 0
            swal.showInputError("You need to state a reason!")
          else
            Meteor.call "logActivity", "reopen questionnaire (#{data.questionnaire.id}) for editing which was already filled out (patient: #{data.patient.id} visit:#{data.visit.title})", "notice", confirmedWithReason, data
            swal.close()
            doShowQuestionnaireWizzard(data)
        return
    else
      doShowQuestionnaireWizzard(data)
  else
    doShowQuestionnaireWizzard(data)

doShowQuestionnaireWizzard = (data) ->
  Modal.show('questionnaireWizzard', data, keyboard: false)


@__closeQuestionnaireWizzard = ->
  if isAFormDirty()
    swal {
      title: 'Unsaved Changes'
      text: "Do you want to save the changes on this page?"
      type: 'warning'
      showCancelButton: true
      confirmButtonText: 'Save and exit'
      cancelButtonText: "Exit without saving"
      closeOnConfirm: false
    }, (save) ->
      if save
        submitAllForms('close')
      else
        swal.close()
        Modal.hide('questionnaireWizzard')
  else
    Modal.hide('questionnaireWizzard')


_numQuestions = new ReactiveVar(0)
_numPages = new ReactiveVar(0)
_questionIdsForPage = new ReactiveVar({})
_pageIndex = new ReactiveVar(0)
_numFormsToSubmit = 0
_readonly = new ReactiveVar(false)
_questionnaire = new ReactiveVar(null)
_nextQuestionnaire = null
_preview = new ReactiveVar(false)
_lang = new ReactiveVar(null)

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
  missingAnswer = false
  optionalQuestions = []
  questions = Questions.find
    questionnaireId: _questionnaire.get()._id
  .map (question) ->
    if question.optional
      optionalQuestions.push(question._id)
  #count forms and check for empty inputs
  $("form").each ->
    e = $(@)
    classes = e.attr('class')
    if classes? and classes.indexOf('question') > -1
      numFormsToSubmit += 1
      if optionalQuestions.indexOf(e.attr('id')) < 0
        if classes? and classes.indexOf('questionForm') > -1
          #check multiple subquestions forms
          lines = e.find('tbody tr')
          lines.each ->
            l = $(@)
            lineAnswered = l.find('input:checked').length > 0
            if !lineAnswered
              missingAnswer = true
              l.addClass("missing-answer")
            else
              l.removeClass("missing-answer")
        else
          #check one question forms
          updateDoc = AutoForm.getFormValues(e.attr('id')).updateDoc
          if Object.keys(updateDoc).length is 0 or updateDoc?['$unset']?.value is ""
            missingAnswer = true
            e.addClass("missing-answer")
          else
            e.removeClass("missing-answer")
  if missingAnswer
      swal {
        title: 'missing answers'
        text: "You have left some questions unanswered, are you sure you want to continue?"
        type: 'warning'
        showCancelButton: true
        confirmButtonText: 'Yes'
        cancelButtonText: "Cancel"
      }, ->
        doSubmitAllForms(numFormsToSubmit)
  else
    swal.close() #possibly open swal "unsaved changes"
    doSubmitAllForms(numFormsToSubmit)

_submittingForms = false
doSubmitAllForms = (numFormsToSubmit) ->
  _submittingForms = true
  _numFormsToSubmit = numFormsToSubmit
  $("form").each ->
    e = $(@)
    classes = e.attr('class')
    if classes? and classes.indexOf('question') > -1
      q = Questions.findOne(e.attr('id'))
      # Remove the answer to conditional question if it is hidden
      if q.conditional?
        value = $('#' + q.conditional).val().value
        parentQuestion = Questions.findOne(q.conditional)
        removeAnswer = true
        if parentQuestion.type is 'multipleChoice'
          selection = parentQuestion.choices.find((x) -> x.value is value)
          if selection?
            removeAnswer = !selection.conditional
        else if parentQuestion.type is 'boolean'
          if (parentQuestion.showCondtionalQuestionsOn? and
              value in parentQuestion.showCondtionalQuestionsOn)
            removeAnswer = false
        if removeAnswer
          e.trigger('reset')
          e.val().value = 'NA'
      e.submit()

formSubmitted = ->
  if (_numFormsToSubmit -= 1) <= 0
    _submittingForms = false
    if _goto is 'nextPage'
      nextPage()
    else if _goto is 'previousPage'
      previousPage()
    else if _goto is 'close'
      Modal.hide('questionnaireWizzard')
    else if _goto? and _goto.pageIndex?
      _pageIndex.set _goto.pageIndex


nextPage = ->
  if _pageIndex.get() is _numPages.get()-1
    # deactiavted: go to next questionnaire automatically
    #if _nextQuestionnaire?
    #  _pageIndex.set 0
    #  _questionnaire.set _nextQuestionnaire
    #else
    Modal.hide('questionnaireWizzard')
  else
    $('modal-content').scrollTop(0)
    _pageIndex.set _pageIndex.get()+1

previousPage = ->
  index = _pageIndex.get()
  index -= 1 if index > 0
  _pageIndex.set index


autoformHooks =
  onSubmit: (insertDoc, updateDoc, currentDoc) ->
    if !_submittingForms #ignore enter press
      @done()
      return false
    if _preview.get() or _readonly.get()
      return
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
    if e.keyCode is 27 #escape
      __closeQuestionnaireWizzard()
    return
  )

  #close if user has been logged out
  @autorun ->
    if !Meteor.user()
      __closeQuestionnaireWizzard()

  self = @
  @autorun ->
    self.subscribe("questionsForQuestionnaire", _questionnaire.get()._id)

  #manage nextQuestionnaire
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
    AutoForm.addHooks(autoformIds, autoformHooks, true)

  #determine language
  @autorun ->
    data = Template.currentData()
    patient = data.patient
    questionnaire = _questionnaire.get()
    if !patient #preview
      _lang.set null
      return
    if patient.primaryLanguage?
      if patient.primaryLanguage is questionnaire.primaryLanguage
        _lang.set null
        return
      if questionnaire.translationLanguages? and questionnaire.translationLanguages.length > 0
        lang = questionnaire.translationLanguages.find (t) ->
          t is patient.primaryLanguage
        if lang?
          _lang.set lang
          return
    if patient.secondaryLanguage?
      if patient.secondaryLanguage is questionnaire.primaryLanguage
        _lang.set null
        return
      if questionnaire.translationLanguages? and questionnaire.translationLanguages.length > 0
        lang = questionnaire.translationLanguages.find (t) ->
          t is patient.secondaryLanguage
        if lang?
          _lang.set lang
          return
    _lang.set null
    return

  @autorun ->
    Template.currentData() #must trigger reselection
    value = _lang.get()
    if !value?
      value = _questionnaire.get().primaryLanguage
    Meteor.setTimeout ->
      $("#source-lang option[value=#{value}]").attr('selected', true)
    , 100


adjustHeaderHeight = ->
  $('.questionnaireWizzard h2.modal-title').css('font-size', '1pt')
  width = $('.questionnaireWizzard .modal-header').width()
  height = $('.questionnaireWizzard .modal-header').height()
  rWidth = $('.questionnaireWizzard .modal-header .regulations').width()
  $('.questionnaireWizzard .title-wrapper').width(width-rWidth-5)
  $('.questionnaireWizzard .title-wrapper').height(height)
  fs = 16
  counter = 0
  while(true)
    if fs > 32
      return
    counter += 1
    $('.questionnaireWizzard h2.modal-title').css('font-size', fs+'pt')
    if $('.questionnaireWizzard h2.modal-title').height() > 60
      $('.questionnaireWizzard h2.modal-title').css('font-size', fs-1+'pt')
      return
    fs += 1

Template.questionnaireWizzard.rendered = ->
  $(window).resize(adjustHeaderHeight)
  Meteor.setTimeout(adjustHeaderHeight, 2000)

Template.questionnaireWizzard.destroyed = ->
  $(document).unbind('keyup.wizzard')
  Session.set('selectedQuestionnaireWizzard', null)
  $(window).off("resize", adjustHeaderHeight)


Template.questionnaireWizzard.helpers
  patientDescription: ->
    d = @patient.id
    if @patient.hrid
      d += " (#{@patient.hrid})"
    d
  userDescription: ->
    getUserDescription(Meteor.user())

  studyTitle: ->
    Studies.findOne(@patient.studyId).title

  language: ->
    lang = _lang.get()
    questionnaire = _questionnaire.get()
    if !lang and questionnaire.primaryLanguage?
      lang = questionnaire.primaryLanguage
    lang

  hasLangs: ->
    _questionnaire.get().primaryLanguage?

  langs: ->
    questionnaire = _questionnaire.get()
    tl = questionnaire.translationLanguages or []
    pl = questionnaire.primaryLanguage
    langs = isoLangs.filter (l) ->
      l.code is pl or tl.indexOf(l.code) > -1
    langs = JSON.parse(JSON.stringify(langs))
    _.some langs, (l) ->
      if l.code is pl
        l.suffix = "- PRIMARY LANGUAGE -"
      l.code is pl
    langs

  templateGestures:
    'swipeleft div': (evt, templateInstance) ->
      nextQuestion()

    'swiperight div': (evt, templateInstance) ->
      previousQuestion()

  title: ->
    _questionnaire.get().title

  questionsForPage: ->
    questionIdsForPage = _questionIdsForPage.get()[_pageIndex.get()]
    cursor = Questions.find(
      questionnaireId: _questionnaire.get()._id
      _id: {$in: questionIdsForPage}
    ,
      sort: {index: 1}
    )
    lang = _lang.get()
    if lang? #we need to translate all questions
      questions = cursor.map (q) ->
        q.translateTo lang
      return questions
    else #no need to translate
      return cursor

  questionnaire: ->
    _questionnaire.get()

  answerForQuestion: (visitId, questionId) ->
    return if _preview.get()
    Answers.findOne
      visitId: visitId
      questionId: questionId

  displayQuestion: (visitId, question) ->
    showQuestion = true
    if question.conditional?
      showQuestion = false
      answer_conditional = Answers.findOne
        visitId: visitId
        questionId: question.conditional
      if answer_conditional?
        parentQuestion = Questions.findOne(question.conditional)
        if parentQuestion.type is 'multipleChoice'
          selection = parentQuestion.choices.find(
            (x) -> x.value is answer_conditional.value)
          if selection?
            showQuestion = selection.conditional
        else if parentQuestion.type is 'boolean'
          if (parentQuestion.showCondtionalQuestionsOn? and
                answer_conditional.value in parentQuestion.showCondtionalQuestionsOn)
              showQuestion = true
    return if showQuestion then '' else 'display:none;'

  readonly: ->
    _readonly.get()

  preview: ->
    _preview.get()

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
        if question.type is "table" or question.type is "table_polar"
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
    # deactiavted: go to next questionnaire automatically
    _pageIndex.get() is _numPages.get()-1# and (_preview.get() or _nextQuestionnaire is null)


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
        closeOnConfirm: false
      }, (save) ->
        if save
          submitAllForms(pageIndex: pageIndex)
        else
          swal.close()
          _pageIndex.set pageIndex
    else
      _pageIndex.set pageIndex
    false

  "click #close": (evt) ->
    __closeQuestionnaireWizzard()
    false

  "submit .questionForm": (evt) -> #table and table_polar
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
      if @question.selectionMode is "multi"
        values = []
        inputs.each ->
          input = $(@)
          values.push input.data('choice_value').toString()
        if values.length > 0
          answer.value.push
            code: subquestion.code
            value: values
      else #if @question.selectionMode is "single"
        if inputs.length > 1
          throw new Meteor.Error('error when processing the values: single selection got multiple values.')
        else if inputs.length is 1
          value = inputs.first().data('choice_value').toString()
          answer.value.push
            code: subquestion.code
            value: value
    if answer.value.length > 0
      Meteor.call "upsertAnswer", answer, (error) ->
        throwError error if error?
        formSubmitted()
    else
      formSubmitted()
    false

  "change #source-lang": (evt) ->
    _lang.set $(evt.target).find(":selected").attr('value')

  "change form": (evt) ->
    question = Questions.findOne(evt.currentTarget.id)
    value = evt.currentTarget.value.value
    showQuestion = false
    if question.type is 'multipleChoice'
      selection = question.choices.find((x) -> x.value is value)
      if selection?
        showQuestion = selection.conditional
    else if question.type is 'boolean'
      if question.showCondtionalQuestionsOn? and value in question.showCondtionalQuestionsOn
        showQuestion = true
    if showQuestion
      $("form[data-conditional='#{evt.currentTarget.id}']").show()
    else
      $("form[data-conditional='#{evt.currentTarget.id}']").hide()
