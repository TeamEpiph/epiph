AutoForm.hooks
  questionnaireForm:
    onSubmit: (insertDoc, updateDoc, currentDoc) ->
      @done()
      false

sortableTimeout = null
Template.autoForm.rendered = ->
  @autorun ->
    id = Session.get 'selectedQuestionId'
    #selectedQuestion = Questions.findOne
    #  _id: id
    $(".form-group").removeClass("selectedQuestion")
    $(".form-group:has(input[data-schema-key=#{id}])").addClass("selectedQuestion")
    $(".form-group:has(div[data-schema-key=#{id}])").addClass("selectedQuestion")
    $(".form-group:has(textarea[data-schema-key=#{id}])").addClass("selectedQuestion")

  Meteor.clearTimeout(sortableTimeout) if sortableTimeout?
  sortableTimeout = Meteor.setTimeout( ->
    try
      $(".questionnaireForm").sortable("destroy")
    $(".questionnaireForm").sortable
      items: ".form-group:not(.ui-sortable-disabled)"
      helper : 'clone'
      start: (e, ui) ->
        index = parseInt ui.item.data("index")
        jIndex = parseInt ui.item.index()
        #throwError "index(#{index}) and jIndex(#{jIndex}) don't match"
        $(this).attr 'data-pIndex', jIndex
        #$(".ui-sortable-disabled").hide()
        return
      stop: (event, ui) -> # fired when an item is dropped
        newIndex = parseInt(ui.item.index())
        oldIndex = parseInt($(this).attr('data-pIndex'))
        $(this).removeAttr 'data-pIndex'
        questionnaireId  = Session.get 'editingQuestionnaireId'
        console.log "#{questionnaireId} #{oldIndex} -> #{newIndex}"
        if newIndex is oldIndex
          $(".questionnaireForm").sortable("cancel")
        else
          Meteor.call "moveQuestion", questionnaireId, oldIndex, newIndex, (error) ->
            if error?
              $(".questionnaireForm").sortable("cancel")
              throwError error
            #else
              #$(".questionnaireForm").sortable("refreshPositions")
              #$(".questionnaireForm").sortable("refresh")
              #$(".ui-sortable-disabled").show()
        return
    , 800)


Template.editQuestionnaire.rendered = ->
  Session.set 'editingQuestionnaireId', @data._id

Template.editQuestionnaire.helpers
  questionnaireSchema: ->
    schema = 
      title:
        type: String
      key:
        type: String
        optional: true
    new SimpleSchema(schema)

  hasQuestions: ->
    Questions.find(
      questionnaireId: @_id
    ).count() > 0

  questionnaireFormSchema: ->
    schema = {}
    Questions.find(
      questionnaireId: @_id
    ,
      sort:
        index: 1
    ).forEach (q) ->
      schema[q._id.toString()] = q.getSchemaDict()
    new SimpleSchema(schema)

  selectedQuestion: ->
    id = Session.get 'selectedQuestionId'
    Questions.findOne
      _id: id

  #this: selectedQuestion
  questionFormSchema: ->
    new SimpleSchema(@getMetaSchemaDict())
      

Template.editQuestionnaire.events
  "click #editQuestionnaire": (evt) ->
    Session.set 'selectedQuestionId', null

  "click #addQuestion": (evt) ->
    question =
      questionnaireId: @_id
      label: "How do you feel today?"
      type: "text"
    Meteor.call "insertQuestion", question, (error, _id) ->
      throwError error if error?
      Session.set 'selectedQuestionId', _id

  "click #copyQuestion": (evt) ->
    sid = Session.get 'selectedQuestionId'
    selectedQuestion = Questions.findOne
      _id: sid
    delete selectedQuestion._id
    delete selectedQuestion.index
    Meteor.call "insertQuestion", selectedQuestion, (error, _id) ->
      throwError error if error?
      Session.set 'selectedQuestionId', _id

  "click #removeQuestion": (evt) ->
    sid = Session.get 'selectedQuestionId'
    if confirm("Delete Question?")
      Meteor.call "removeQuestion", sid, (error, _id) ->
        throwError error if error?
        Session.set 'selectedQuestionId', null

  "click #validate": (evt) ->
    AutoForm.validateForm("questionnaireForm")

  "click .questionnaireForm > .form-group": (evt) ->
    target = $(evt.target)
    id = target.closest(".form-group").find("input").data('schema-key')
    if !id?
      id = target.closest(".form-group").find("div").data('schema-key')
    if !id?
      id = target.closest(".form-group").find("textarea").data('schema-key')
      
    Session.set 'selectedQuestionId', id
