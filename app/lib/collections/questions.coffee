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
        s.type = Number
        s.autoform = 
          type: "select-radio-inline"
          options: @choices
    delete s.options
    s

  getMetaSchemaDict: ->
    schema =
      label:
        label: "Question"
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
    schema
    

@Questions = new Meteor.Collection("questions",
  transform: (doc) ->
    new Question(doc)
)

Questions.before.insert BeforeInsertTimestampHook
Questions.before.update BeforeUpdateTimestampHook

Questions.allow
  insert: (userId, doc) ->
    questionnaire = Questionnaires.findOne
      _id: doc.questionnaireId
    questionnaire.creatorId is userId
  update: (userId, doc, fieldNames, modifier) ->
    questionnaire = Questionnaires.findOne
      _id: doc.questionnaireId
    questionnaire.creatorId is userId
  remove: (userId, doc) ->
    questionnaire = Questionnaires.findOne
      _id: doc.questionnaireId
    questionnaire.creatorId is userId

Meteor.methods
  "insertQuestion": (question) ->
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

  "removeQuestion": (_id) ->
    check(_id, String)
    question = Questions.findOne _id
    questionnaire = Questionnaires.findOne
      _id:  question.questionnaireId
    throw new Meteor.Error(403, "Only the creator of the questionnaire is allowed to edit it's questions.") unless questionnaire.creatorId is Meteor.userId()

    Questions.remove _id
