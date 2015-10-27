class @Question
  constructor: (doc) ->
    _.extend this, doc

  getSchemaDict: ->
    s = _.pickDeep @, 'type', 'label', 'optional', 'min', 'max', 'decimal', 'options', 'options.label', 'options.value'
    switch @type
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
        s.autoform = 
          options: @choices
        if @mode is "radio"
          s.type = Number
          s.autoform.type = "select-radio-inline"
        else if @mode is "checkbox"
          s.type = [Number]
          s.autoform.type = "select-checkbox-inline"
      when "table"
        s.type = Number
      when "markdown"
        s.type = String
        s.label = ' ' 
        s.autoform = 
          type: "markdown"
    delete s.options
    s

  getMetaSchemaDict: ->
    schema = {}

    if @type isnt "markdown"
      _.extend schema, 
        code:
          label: "Code"
          type: String
          optional: true
        label:
          label: "Question"
          type: String
          autoform:
            type: "textarea"
        optional:
          label: "Optional"
          type: Boolean

    _.extend schema, 
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
              {label: "Table", value: "table"},
              {label: "Description (no question)", value: "markdown"},
            ]

    if @type is "multipleChoice" or "table"
      _.extend schema, 
        mode:
          label: "Mode"
          type: String
          autoform:
            type: "select-radio-inline"
            options: [
              label: "single selection (radios)"
              value: "radio"
            ,
              label: "multiple selection (checkboxes)"
              value: "checkbox"
            ]

    if @type is "markdown"
      _.extend schema, 
        label:
          label: "Text"
          type: String
          autoform:
            type: "textarea"
            rows: 10

    #_.extend schema, 
    #  break:
    #    label: "Break after this question"
    #    type: Boolean

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
      #when "date"
      #  _.extend schema, 
      #    min:
      #      type: Date
      #      optional: true
      #      #autoform:
      #      #  type: "bootstrap-datepicker"
      #    max:
      #      type: Date
      #      optional: true
      #      #autoform:
      #      #  type: "bootstrap-datepicker"
      #when "dateTime"
      #  _.extend schema, 
      #    min:
      #      type: Date
      #      optional: true
      #      #autoform:
      #      #  type: "bootstrap-datetimepicker"
      #    max:
      #      type: Date
      #      optional: true
      #      #autoform:
      #      #  type: "bootstrap-datetimepicker"
      when "table"
        _.extend schema, 
          subquestions:
            type: [String]
            label: "Subquestions"
            minCount: 1
    switch @type
      when "multipleChoice", "table"
        _.extend schema, 
          choices:
            type: [Object]
            label: "Choices"
            minCount: 1
          'choices.$.label':
            type: String
          'choices.$.value':
            type: Number
    schema
    

@Questions = new Meteor.Collection("questions",
  transform: (doc) ->
    new Question(doc)
)

Questions.before.insert BeforeInsertTimestampHook
Questions.before.update BeforeUpdateTimestampHook

#TODO check if allowed
#TODO check consistency
Questions.allow
  insert: (userId, doc) ->
    true
  update: (userId, doc, fieldNames, modifier) ->
    true
  remove: (userId, doc) ->
    true

Meteor.methods
  insertQuestion: (question) ->
    check(question.questionnaireId, String)
    questionnaire = Questionnaires.findOne
      _id:  question.questionnaireId
    throw new Meteor.Error(403, "Only the creator of the questionnaire is allowed to edit it's questions.") unless questionnaire.creatorId is Meteor.userId()

    check(question.label, String)
    check(question.type, String)

    numQuestions = Questions.find
      questionnaireId: questionnaire._id
    .count()
    nextIndex = numQuestions+1
    if (question.index? and question.index > nextIndex) or !question.index?
      question.index = nextIndex 

    #TODO filter question atters
    _id = Questions.insert question
    _id

  removeQuestion: (_id) ->
    check(_id, String)
    question = Questions.findOne _id
    questionnaire = Questionnaires.findOne
      _id:  question.questionnaireId
    throw new Meteor.Error(403, "Only the creator of the questionnaire is allowed to edit it's questions.") unless questionnaire.creatorId is Meteor.userId()

    Questions.remove _id

    Questions.update
      questionnaireId: questionnaire._id
      index: { $gt: question.index }
    ,
      $inc: { index: -1 }
    ,
      multi: true


  moveQuestion: (questionnaireId, oldIndex, newIndex) ->
    check(questionnaireId, String)
    check(oldIndex, Match.Integer)
    check(newIndex, Match.Integer)

    questionnaire = Questionnaires.findOne
      _id:  questionnaireId
    throw new Meteor.Error(403, "Only the creator of the questionnaire is allowed to edit it's questions.") unless questionnaire.creatorId is Meteor.userId()

    question = Questions.findOne
      questionnaireId: questionnaireId
      index: oldIndex
    throw new Meteor.Error(403, "question with index #{oldIndex} not found.") unless question?

    Questions.update
      questionnaireId: questionnaireId
      index: { $gt: oldIndex }
    ,
      $inc: { index: -1 }
    ,
      multi: true
    Questions.update
      questionnaireId: questionnaireId
      index: { $gte: newIndex }
    ,
      $inc: { index: 1 }
    ,
      multi: true
    Questions.update
      _id: question._id
    ,
      $set: { index: newIndex}
    null
