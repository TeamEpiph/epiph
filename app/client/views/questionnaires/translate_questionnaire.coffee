destinationLang = new ReactiveVar('en')
sourceLang = new ReactiveVar(null)


_numFormsToSubmit = 0
submitAllForms = ->
  numFormsToSubmit = 0
  $("form").each ->
    e = $(@)
    classes = e.attr('class')
    if classes? and classes.indexOf('translationForm') > -1
      numFormsToSubmit += 1
  doSubmitAllForms(numFormsToSubmit)

_submittingForms = false
doSubmitAllForms = (numFormsToSubmit) ->
  _submittingForms = true
  _numFormsToSubmit = numFormsToSubmit
  $("form").each ->
    e = $(@)
    classes = e.attr('class')
    if classes? and classes.indexOf('translationForm') > -1
      e.submit()

formSubmitted = ->
  if (_numFormsToSubmit -= 1) <= 0
    _submittingForms = false
    console.log "allFormsSubmitted"

autoformHooks = 
  onSubmit: (insertDoc, updateDoc, currentDoc) ->
    if Object.keys(insertDoc).length > 0
      Meteor.call "translateQuestion", @formId, insertDoc, destinationLang.get(), (error) ->
        throwError error if error?
    formSubmitted()
    @done()
    false


Template.translateQuestionnaireSourceLang.rendered = ->
  @autorun ->
    console.log "set sourceLang"
    Meteor.setTimeout ->
      $("#source-lang option[value=#{sourceLang.get()}]").attr('selected', true)
    , 100

Template.translateQuestionnaireSourceLang.helpers
  langs: ->
    tl = @translationLanguages or []
    pl = @primaryLanguage
    isoLangs.filter (l) ->
      l.code is pl or tl.indexOf(l.code) > -1
    
Template.translateQuestionnaireSourceLang.events
  "change #sourceLang-lang": (evt) ->
    sourceLang.set $(evt.target).find(":selected").attr('value')


Template.translateQuestionnaireDestinationLang.rendered = ->
  @autorun ->
    console.log "set destinationLang"
    Meteor.setTimeout ->
      $("#destination-lang option[value=#{destinationLang.get()}]").attr('selected', true)
    , 100

Template.translateQuestionnaireDestinationLang.helpers
  langs: ->
    pl = @primaryLanguage
    isoLangs.filter (l) ->
      l.code isnt pl

Template.translateQuestionnaireDestinationLang.events
  "change #destination-lang": (evt) ->
    destinationLang.set $(evt.target).find(":selected").attr('value')


Template.translateQuestionnaire.rendered = ->
  questionnaire = @data
  if !questionnaire.translationLanguages?
    questionnaire.translationLanguages = []

  #redirect if primaryLang isn't set
  if !questionnaire.primaryLanguage
    swal {
      title: 'Error!'
      text: 'You need to set the primary language of that questionnaire before you can translate it. You will be redirected to the edit page.'
      type: 'warning'
      showCancelButton: false
    }, ->
      Router.go "editQuestionnaire", _id: questionnaire._id
    return

  #check source lang
  pl = questionnaire.primaryLanguage
  sl = sourceLang.get()
  if !sl? or (sl isnt pl and questionnaire.translationLanguages.indexOf(sl) is -1)
    sourceLang.set questionnaire.primaryLanguage
  #check destination lang
  dl = destinationLang.get()
  if dl is pl
    if pl is "en"
      destinationLang.set "es"
    else if pl is "es"
      destinationLang.set "en"

  #hook formIds
  autoformIds = Questions.find(
    questionnaireId: @data._id
  ).map (q) ->
    q._id
  AutoForm.addHooks(autoformIds, autoformHooks, true)
  return

Template.translateQuestionnaire.helpers
  questionnaireSchema: ->
    schema = 
      title:
        type: String
      id:
        label: 'ID'
        type: String
        optional: true
    new SimpleSchema(schema)

  hasQuestions: ->
    Questions.find(
      questionnaireId: @_id
    ).count() > 0

  allQuestions: ->
    Questions.find(
      questionnaireId: @_id
      #_id: "JvAN9d6bzzjct3mbK"
    ,
      sort: index: 1
    )

  editQuestionnaireQuestionOptions: ->
    q = _.clone @
    schema = {}
    schema[q._id.toString()] = q.getSchemaDict()
    q.schema = new SimpleSchema(schema)
    question: q
    options: null


Template.translateQuestionnaire.events
  "click #submitTranslation": (evt) ->
    submitAllForms()

  "click #editQuestionnaire": (evt) ->
    console.log "editQuestionnaire"

  "click #previewQuestionnaire": (evt) ->
    data =
      questionnaire: @
      visit: null
      patient: null
      preview: true
    Modal.show('questionnaireWizzard', data, keyboard: false)
    false


Template.editQuestionnaireQuestionTranslate.helpers
  doc: ->
    lang = destinationLang.get()
    if !@translations? or !@translations[lang]?
      @
    else
      @translations[lang]

  questionTranslationFormSchema: ->
    new SimpleSchema(@getTranslationSchemaDict())
