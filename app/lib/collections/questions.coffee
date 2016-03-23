class @Question
  constructor: (doc) ->
    _.extend this, doc

  getSchemaDict: ->
    s = _.pickDeep @, 'type', 'label', 'optional', 'min', 'max', 'decimal', 'options', 'options.label', 'options.value'
    switch @type
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
        if @mode is "checkbox"
          s.type = [Number]
          if @orientation is 'inline'
            s.autoform.type = "select-checkbox-inline"
          else #if @orientation is 'vertical'
            s.autoform.type = "select-checkbox"
        else #if @mode is "radio"
          s.type = Number
          if @orientation is 'inline'
            s.autoform.type = "select-radio-inline"
          else #if @orientation is 'vertical'
            s.autoform.type = "select-radio"
      when "table"
        s.type = Number
      when "description"
        s.type = String
        s.label = ' ' 
        s.autoform = 
          type: "description"
    delete s.options
    s


  getMetaSchemaDict: ->
    schema = {}

    noWhitespaceRegex = /^\S*$/ #don't match if contains whitespace
    if @type isnt "description"
      _.extend schema, 
        code:
          label: "Code"
          type: String
          optional: false
          regEx: noWhitespaceRegex
        optional:
          label: "Optional"
          type: Boolean
        label:
          label: if (@type is "table" or @type is 'table_polar') then "Title" else "Question"
          type: String
          optional: (@type is "table" or @type is 'table_polar')
          autoform:
            type: "textarea"

    _.extend schema, 
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
              {label: "Date & Time", value: "dateTime"},
              {label: "Multiple Choice", value: "multipleChoice"},
              {label: "Table Multiple Choice", value: "table"},
              {label: "Table Polar", value: "table_polar"},
              {label: "Description (no question)", value: "description"},
            ]
      break:
        label: "insert pagebreak after this item"
        type: Boolean

    if @type is "multipleChoice" or @type is "table" or @type is "table_polar"
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

    if @type is "multipleChoice"
      _.extend schema, 
        orientation:
          label: "Orientation"
          type: String
          autoform:
            type: "select-radio-inline"
            options: [
              label: "inline"
              value: "inline"
            ,
              label: "vertical"
              value: "vertical"
            ]

    if @type is "description"
      _.extend schema, 
        label:
          label: "Text (markdown)"
          type: String
          autoform:
            type: "textarea"
            rows: 10

    if @type is "number"
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

    if @type is "multipleChoice" or @type is "table" or @type is "table_polar"
      _.extend schema, 
        choices:
          type: [Object]
          label: "Choices"
          minCount: 1
        'choices.$.label':
          type: String
          optional: true
        'choices.$.variable':
          type: String
          regEx: noWhitespaceRegex
          custom: ->
            #console.log "> #{@value} #{@key} <"
            #console.log "----"
            digitRegex = /(\d+)/g
            matches = digitRegex.exec(@key)
            if matches.length > 0
              index = parseInt(matches[0])-1
              while index >= 0
                v = @field("choices.#{index}.variable").value
                #console.log v
                if v? and v.valueOf() is @value.valueOf()
                  return "notUnique"
                index -= 1
            return
        'choices.$.value':
          type: String
          regEx: noWhitespaceRegex

    if @type is "table"
      _.extend schema, 
        subquestions:
          type: [Object]
          label: "Subquestions"
          minCount: 1
        'subquestions.$.label':
          type: String
          autoform:
            type: "textarea"
        'subquestions.$.code':
          type: String
          regEx: noWhitespaceRegex
          custom: ->
            digitRegex = /(\d+)/g
            matches = digitRegex.exec(@key)
            if matches.length > 0
              index = parseInt(matches[0])-1
              while index >= 0
                v = @field("subquestions.#{index}.code").value
                if v? and v.valueOf() is @value.valueOf()
                  return "notUnique"
                index -= 1
            return

    if @type is "table_polar"
      _.extend schema, 
        subquestions:
          type: [Object]
          label: "Subquestions"
          minCount: 1
        'subquestions.$.minLabel':
          label: "min label"
          type: String
        'subquestions.$.maxLabel':
          label: "max label"
          type: String
        'subquestions.$.code':
          type: String
          regEx: noWhitespaceRegex
          custom: ->
            digitRegex = /(\d+)/g
            matches = digitRegex.exec(@key)
            if matches.length > 0
              index = parseInt(matches[0])-1
              while index >= 0
                v = @field("subquestions.#{index}.code").value
                if v? and v.valueOf() is @value.valueOf()
                  return "notUnique"
                index -= 1
            return


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

    check(question.type, String)
    if question.type isnt 'table' and question.type isnt 'table_polar'
      check(question.label, String)

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
