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
      s = _.pickDeep q, 'type', 'label', 'optional', 'min', 'max', 'decimal', 'options', 'options.label', 'options.value'
      switch q.type
        when "string"
          s.type = String
        when "text"
          s.type = String
          s.autoform = 
            type: "textarea"
        when "number"
          s.type = Number
        when "boolean"
          s.type = Boolean
          s.autoform = 
            type: "boolean-radios"
        when "date"
          s.type = Date
          s.autoform = 
            type: "bootstrap-datepicker"
        when "dateTime"
          s.type = Date
          s.autoform = 
            type: "bootstrap-datetimepicker"
        when "multipleChoice"
          s.type = String
          s.autoform = 
            type: "select-radio-inline"
            options: q.choices
      delete s.options
      schema[q._id.toString()] = s
    console.log "questionnaireFormSchema"
    console.log schema
    new SimpleSchema(schema)

  selectedQuestion: ->
    id = Session.get 'selectedQuestionId'
    Questions.findOne
      _id: id

  #this: selectedQuestion
  questionFormSchema: ->
    schema =
      label:
        label: "Label"
        type: String
      optional:
        label: "Optional"
        type: Boolean
      #tag:
      #  label: "Tag"
      #  type: String
      #  optional: true
      #legend:
      #  label: "Scale legend"
      #  type: String
      #  optional: true
      #  autoform:
      #    afFieldInput:
      #      type: "textarea"
      type:
        label: "Type"
        type: String
        autoform:
          type: "select"
          options: ->
            [
              {label: "String", value: "string"},
              {label: "Text", value: "text"},
              {label: "Number", value: "number"},
              {label: "Boolean", value: "boolean"},
              {label: "Date", value: "date"},
              {label: "Date & Time", value: "dateTime"},
              {label: "Multiple Choice", value: "multipleChoice"},
            ]

    switch @type
      when "string", "text"
        _.extend schema, 
          min:
            type: Number
            optional: true
          max:
            type: Number
            optional: true
      when "number"
        _.extend schema, 
          min:
            type: Number
            optional: true
            decimal: true
          max:
            type: Number
            optional: true
            decimal: true
          decimal:
            type: Boolean
      when "date"
        _.extend schema, 
          min:
            type: Date
            optional: true
            #autoform:
            #  type: "bootstrap-datepicker"
          max:
            type: Date
            optional: true
            #autoform:
            #  type: "bootstrap-datepicker"
      when "dateTime"
        _.extend schema, 
          min:
            type: Date
            optional: true
            #autoform:
            #  type: "bootstrap-datetimepicker"
          max:
            type: Date
            optional: true
            #autoform:
            #  type: "bootstrap-datetimepicker"
      when "multipleChoice"
        _.extend schema, 
          choices:
            type: [Object]
            label: "Choices"
            minCount: 1
          'choices.$.label':
            type: String
          'choices.$.value':
            type: Number
    new SimpleSchema(schema)
      

Template.editQuestionnaire.events
  "click #editQuestionnaire": (evt) ->
    Session.set 'selectedQuestionId', null

  "click #addQuestion": (evt) ->
    numQuestions = Questions.find
      questionnaireId: @_id
    .count()
    maxIndex = numQuestions-1
    maxIndex = 0 if maxIndex < 0

    id = Questions.insert
      questionnaireId: @_id
      label: "What's the question?"
      type: "text"
      index: maxIndex
    Session.set 'selectedQuestionId', id

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
