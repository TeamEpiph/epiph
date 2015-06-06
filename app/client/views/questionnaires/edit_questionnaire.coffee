Template.editQuestionnaire.helpers
  questions: ->
    Questions.find
      questionnaireId: @_id

  questionnaireFormId: ->
    @_id+"_form"

  questionnaireFormSchema: ->
    schema = {}
    Questions.find(
      questionnaireId: @_id
    ).forEach (q) ->
      s = _.pickDeep q, 'type', 'label', 'min', 'max', 'decimal', 'options', 'options.label', 'options.value'
      switch q.type
        when "string"
          s.type = String
        when "number"
          s.type = Number
        when "boolean"
          s.type = Boolean
        when "date"
          s.type = Date
        when "multipleChoice"
          s.type = "string"
          s.autoform = 
            type: "select-radio-inline"
            options: q.options
            #options: ->
            #  [
            #    {label: "1", value: "1"}
            #    {label: "2", value: "2"}
            #    {label: "3", value: "3"}
            #  ]
      delete s.options
      schema[q._id.toString()] = s
    console.log "questionnaireFormSchema"
    console.log schema
    new SimpleSchema(schema)

  selectedQuestion: ->
    id = Session.get 'selectedQuestionId'
    #FIXME
    $(".form-group").removeClass("selectedQuestion")
    $(".form-group:has(input[data-schema-key=#{id}])").addClass("selectedQuestion")
    #
    Questions.findOne
      _id: id

  #this: selectedQuestion
  questionFormId: ->
    @_id+"_form"
  questionFormSchema: ->
    schema =
      label:
        label: "Label"
        type: String
      type:
        label: "Type"
        type: String
        autoform:
          type: "select"
          options: ->
            [
              {label: "Text", value: "text"},
              {label: "Number", value: "number"},
              {label: "Boolean", value: "boolean"},
              {label: "Date", value: "date"},
              {label: "Multiple Choice", value: "multipleChoice"},
            ]
    switch @type
      when "string"
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
          max:
            type: Number
            optional: true
          decimal:
            type: Boolean
      when "date"
        _.extend schema, 
          min:
            type: Date
            optional: true
          max:
            type: Date
            optional: true
      when "multipleChoice"
        _.extend schema, 
          options:
            type: [Object]
            label: "Choices"
          'options.$.label':
            type: String
          'options.$.value':
            type: Number
    new SimpleSchema(schema)
      

Template.editQuestionnaire.events
  "click #addQuestion": (evt) ->
    id = Questions.insert
      questionnaireId: @_id
      label: "What's the question?"
      type: "text"
    Session.set 'selectedQuestionId', id

  "click .questionnaireForm > .form-group": (evt) ->
    target = $(evt.target)
    id = target.closest(".form-group").find("input").data('schema-key')
    if !id?
      id = target.closest(".form-group").find("div").data('schema-key')
      
    Session.set 'selectedQuestionId', id
