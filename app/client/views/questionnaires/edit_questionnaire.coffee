AutoForm.hooks
  questionnaireForm:
    onSubmit: (insertDoc, updateDoc, currentDoc) ->
      @done()
      false


resizeQuestionEditor = ->
  qe = $('#questionEditor')
  parent = qe.parent() 
  qe.width( parent.width() )

Template.editQuestionnaire.rendered = ->
  Session.set 'editingQuestionnaireId', @data._id
  $(window).resize(resizeQuestionEditor)
  resizeQuestionEditor()
  @autorun ->
    sqId = Session.get 'selectedQuestionId'
    sq = $(".question[data-id=#{sqId}]")
    #FIXME breakpoint
    if sq? and sq.offset()? and $(document).width() > 992
      if $(document).width() > 992
        $("#questionEditor").css("margin-top", sq.offset().top-150)
    else
      $("#questionEditor").css("margin-top", "")
    return

Template.editQuestionnaire.destroyed = ->
  $(window).off("resize", resizeQuestionEditor)


Template.editQuestionnaire.helpers
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
  "change [data-schema-key=type]": (evt) ->
    #override autoform update to allow changing
    #type without validation
    evt.preventDefault()
    evt.stopPropagation()
    Questions.update Session.get('selectedQuestionId'),
      $set:
        type: evt.target.value
    false

  "click #editQuestionnaire": (evt) ->
    Session.set 'selectedQuestionId', null

  "click #addQuestion": (evt) ->
    question =
      questionnaireId: @_id
      label: " "
      type: "text"
      optional: true
    Meteor.call "insertQuestion", question, (error, _id) ->
      throwError error if error?
      Session.set 'selectedQuestionId', _id

  "click #addText": (evt) ->
    question =
      questionnaireId: @_id
      label: " "
      type: "description"
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
    swal {
      title: 'Are you sure?'
      text: 'Do you really want to delete this question?'
      type: 'warning'
      showCancelButton: true
      confirmButtonText: 'Yes'
    }, ->
      Meteor.call "removeQuestion", sid, (error, _id) ->
        throwError error if error?
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
        index = ui.item.index()+1
        #console.log index
        $(this).attr('data-pIndex', index)
        return
      stop: (event, ui) -> # fired when an item is dropped
        #our indices begin at 1
        newIndex = parseInt(ui.item.index())+1
        #oldIndex = parseInt(ui.item.data("index"))
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
              #$(".questionnaireForm").sortable("refreshPositions")
              $(".questionnaireForm").sortable("refresh")
              #$(".ui-sortable-disabled").show()
        return
    , 800)

