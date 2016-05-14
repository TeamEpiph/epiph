_isFullscreen = new ReactiveVar(false)

AutoForm.hooks
  questionsDummyForm:
    onSubmit: (insertDoc, updateDoc, currentDoc) ->
      @done()
      false
  questionnaireEditForm:
    onSubmit: (insertDoc, modifier, currentDoc) ->
      form = @
      Meteor.call "updateQuestionnaire", modifier, currentDoc._id, (error) ->
        if error?
          if error.reason is "questionnaireIsUsedProvideReason"
            swal {
              title: 'Attention!'
              text: """The questionnaire you are about to change is used in studies. If you continue the changes are reflected on all places already using the questionnaire. A log entry will be created. If you want to proceed please state a reason:"""
              type: 'input'
              showCancelButton: true
              confirmButtonText: 'Yes'
              inputPlaceholder: "Please state a reason."
              closeOnConfirm: false
            }, (confirmedWithReason)->
              if confirmedWithReason is false #cancel
                swal.close()
                form.done()
              else
                if !confirmedWithReason? or confirmedWithReason.length is 0
                  swal.showInputError("You need to state a reason!")
                else
                  Meteor.call "updateQuestionnaire", modifier, currentDoc._id, confirmedWithReason, (error2) ->
                    if error2?
                      form.done(error2)
                    else
                      swal.close()
                      form.done()
              return
          else 
            form.done(error)
        else
          form.done()
      false


resizeQuestionEditor = ->
  qe = $('#questionEditor')
  parent = qe.parent() 
  qe.width( parent.width() )

repositionQuestionEditor = ->
  sqId = Session.get 'selectedQuestionId'
  sq = $(".question[data-id=#{sqId}]")
  #FIXME breakpoint
  if !_isFullscreen.get() and sq? and sq.offset()? and $(document).width() > 992
    if $(document).width() > 992
      $("#questionEditor").css("margin-top", sq.offset().top-200)
  else
    $("#questionEditor").css("margin-top", "")
  return

scrollToEditingQuestion = ->
  sqId = Session.get 'selectedQuestionId'
  sq = $(".question[data-id=#{sqId}]")
  $('body').scrollTop sq.offset().top-170

warnIfQuestionFormIsDirty = ->
  form = $('#questionForm')[0]
  if form? && formIsDirty(form)
    document.activeElement.blur()
    scrollToEditingQuestion()
    swal {
      title: 'Unsaved Changes'
      text: "Please save or reset your changes to the editing question before taking other actions."
      type: 'warning'
      showCancelButton: false
      confirmButtonText: 'OK'
    }
    return true
  else
    return false


Template.editQuestionnaire.rendered = ->
  Session.set 'editingQuestionnaireId', @data._id
  $(window).resize(resizeQuestionEditor)
  resizeQuestionEditor()
  @autorun ->
    repositionQuestionEditor()
    return

Template.editQuestionnaire.destroyed = ->
  $(window).off("resize", resizeQuestionEditor)


Template.editQuestionnaire.helpers
  isFullscreen: ->
    _isFullscreen.get()

  questionEditorColClass: ->
    if _isFullscreen.get()
      "col-xs-12 col-md-12"
    else
      "col-xs-12 col-md-6"

  fullscreenToggleFAClass: ->
    if _isFullscreen.get()
      "fa-angle-right"
    else
      "fa-angle-left"


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

  questionSchemas: ->
    Questions.find(
      questionnaireId: @_id
    ,
      sort:
        index: 1
    ).map (q) ->
      schema = {}
      schema[q._id.toString()] = q.getSchemaDict()
      q.schema = new SimpleSchema(schema)
      q

  selectedQuestion: ->
    id = Session.get 'selectedQuestionId'
    Questions.findOne
      _id: id

  #this: selectedQuestion
  questionFormSchema: ->
    new SimpleSchema(@getMetaSchemaDict())
      

Template.editQuestionnaire.events
  "click #toggleFullscreen": (evt) ->
    isFullscreen = !_isFullscreen.get()
    _isFullscreen.set(isFullscreen)
    Meteor.setTimeout ->
      resizeQuestionEditor()
      repositionQuestionEditor()
      if isFullscreen
          $('body').scrollTop 0
      else
        Meteor.setTimeout scrollToEditingQuestion, 300
    , 300
    return

  "change [data-schema-key=type]": (evt) ->
    #override autoform update to allow changing
    #type without validation
    evt.preventDefault()
    evt.stopPropagation()
    questionId = Session.get('selectedQuestionId')
    question = Questions.findOne questionId
    t = question.type
    newType = evt.target.value
    changeQuestionType = (questionId, newType) ->
      Meteor.call "updateQuestion", 
        $set: type: newType
      ,
        questionId
      , (error) ->
        if error?
          Meteor.setTimeout ->
            AutoForm.resetForm('questionForm')
            throwError error
          , 50
    if t isnt "multipleChoice" and t isnt "table" and t isnt "table_polar"
      changeQuestionType(questionId, newType)
    else
      swal {
        title: 'Are you sure?'
        text: 'Do you really want to change the question type?\nThis operation is submitted immediately and you might loose data of your question (eg. subquestions or choices).'
        type: 'warning'
        showCancelButton: true
        confirmButtonText: 'Yes'
      }, (confirmed) ->
        if confirmed
          changeQuestionType(questionId, newType)
        else
          AutoForm.resetForm('questionForm')
        return
    false

  "click #editQuestionnaire": (evt) ->
    if !warnIfQuestionFormIsDirty()
      Session.set 'selectedQuestionId', null

  "click #previewQuestionnaire": (evt) ->
    data =
      questionnaire: @
      visit: null
      patient: null
      preview: true
    Modal.show('questionnaireWizzard', data, keyboard: false)
    false

  "click #addQuestion": (evt) ->
    return if warnIfQuestionFormIsDirty()
    question =
      questionnaireId: @_id
      type: "text"
    Meteor.call "insertQuestion", question, (error, _id) ->
      throwError error if error?
      Session.set 'selectedQuestionId', _id
      Meteor.setTimeout scrollToEditingQuestion, 300

  "click #addText": (evt) ->
    return if warnIfQuestionFormIsDirty()
    question =
      questionnaireId: @_id
      type: "description"
    Meteor.call "insertQuestion", question, (error, _id) ->
      throwError error if error?
      Session.set 'selectedQuestionId', _id
      Meteor.setTimeout scrollToEditingQuestion, 300

  "click #copyQuestion": (evt) ->
    return if warnIfQuestionFormIsDirty()
    questionId = Session.get 'selectedQuestionId'
    Meteor.call "copyQuestion", questionId, (error, _id) ->
      throwError error if error?
      Session.set 'selectedQuestionId', _id
      Meteor.setTimeout scrollToEditingQuestion, 300
    return false

  "click #removeQuestion": (evt) ->
    sid = Session.get 'selectedQuestionId'
    swal {
      title: 'Are you sure?'
      text: 'Do you really want to delete this question?'
      type: 'warning'
      showCancelButton: true
      confirmButtonText: 'Yes'
    }, ->
      Meteor.call "removeQuestion", sid, (error) ->
        if error?
          Meteor.setTimeout ->
            AutoForm.resetForm('questionForm')
            throwError error
          , 50
        else
          Session.set 'selectedQuestionId', null
      return
    return false


Template.editQuestionnaireQuestion.helpers
  #this question
  questionCSS: ->
    if @_id is Session.get("selectedQuestionId")
      "selectedQuestion"
    else
      ""

Template.editQuestionnaireQuestion.events
  "click .question": (evt) ->
    if !warnIfQuestionFormIsDirty()
      Session.set 'selectedQuestionId', @_id


sortableTimeout = null
Template.editQuestionnaireQuestion.rendered = ->
  Meteor.clearTimeout(sortableTimeout) if sortableTimeout?
  sortableTimeout = Meteor.setTimeout( ->
    #try
    #  $(".questions").sortable("destroy")
    $(".questions").sortable
      items: ".question:not(.ui-sortable-disabled)"
      #helper : 'clone'
      #don't trust ui! after (d'n'd) the DOM is updated
      #correctly by blaze ui.item will still hold
      #the old item with the old index! WTF!
      #so we can't use ui.item.data("index")
      start: (e, ui) ->
        #$(".ui-sortable-disabled").hide()
        #console.log parseInt(ui.item.data("index"))
        #our indices begin at 1
        index = $(ui.item).data('index')
        $(this).attr('data-pIndex', index)
        return
      stop: (event, ui) -> # fired when an item is dropped
        #our indices begin at 1
        newIndex = parseInt(ui.item.index())+1
        oldIndex = parseInt($(this).attr('data-pIndex'))

        questionnaireId  = Session.get 'editingQuestionnaireId'
        #console.log "#{questionnaireId} #{oldIndex} -> #{newIndex}"
        if newIndex is oldIndex
          $(".questions").sortable("cancel")
        else
          Meteor.call "moveQuestion", questionnaireId, oldIndex, newIndex, (error) ->
            if error?
              $(".questions").sortable("cancel")
              throwError error
            else
              repositionQuestionEditor()
        return
    , 800)

