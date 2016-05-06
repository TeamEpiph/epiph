class @Question
  constructor: (doc) ->
    _.extend this, doc

  getModifiedPlainObject: (modifier) ->
    TempCollection = new Mongo.Collection("temp", connection: null)
    TempCollection.insert(@)
    selector = { _id: @_id }
    TempCollection.update(selector, modifier)
    simulation = TempCollection.findOne(selector)
    TempCollection.remove(selector)
    simulation.updatedAt = Date.now()
    JSON.parse(JSON.stringify(simulation))

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
        if @selectionMode is "multi"
          s.type = [String]
          if @orientation is 'inline'
            s.autoform.type = "select-checkbox-inline"
          else #if @orientation is 'vertical'
            s.autoform.type = "select-checkbox"
        else #if @selectionMode is "single"
          s.type = String
          if @orientation is 'inline'
            s.autoform.type = "select-radio-inline"
          else #if @orientation is 'vertical'
            s.autoform.type = "select-radio"
      when "description"
        s.type = String
        s.label = ' '
        s.autoform =
          type: "description"
    delete s.options
    return s


  getMetaSchemaDict: (finalValidation)->
    schema = {}
    noWhitespaceRegex = /^\S*$/ #don't match if contains whitespace

    if @type is "table" or @type is "table_polar"
      _.extend schema,
        label:
          label: "Title"
          type: String
          optional: true
          autoform:
            type: "textarea"
    else if @type isnt "description"
      _.extend schema,
        code:
          label: "Code"
          type: String
          regEx: noWhitespaceRegex
          defaultValue: new Mongo.ObjectID()._str
        label:
          label: "Question"
          type: String
          defaultValue: "Insert label here"
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
        defaultValue: false

    if @type isnt "description"
      _.extend schema,
        optional:
          label: "Optional"
          type: Boolean
          defaultValue: true

    if @type is "multipleChoice" or @type is "table" or @type is "table_polar"
      _.extend schema,
        selectionMode:
          label: "Mode"
          type: String
          defaultValue: "single"
          autoform:
            type: "select-radio-inline"
            options: [
              label: "single selection (radios)"
              value: "single"
            ,
              label: "multiple selections (checkboxes)"
              value: "multi"
            ]

    if @type is "multipleChoice"
      _.extend schema,
        orientation:
          label: "Orientation"
          type: String
          defaultValue: "vertical"
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
          defaultValue: "Insert text here"
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
          defaultValue: [{label: "Insert choice here", value: "1"}]
        'choices.$.label':
          type: String
          optional: true
        'choices.$.value':
          type: String
          regEx: noWhitespaceRegex
      if @selectionMode is "multi"
        schema['choices.$.value'].custom = ->
          #console.log "> #{@value} #{@key} <"
          #console.log "----"
          digitRegex = /(\d+)/g
          matches = digitRegex.exec(@key)
          if matches.length > 0
            index = parseInt(matches[0])-1
            while index >= 0
              v = @field("choices.#{index}.value").value
              #console.log v
              if v? and v.valueOf() is @value.valueOf()
                return "notUnique"
              index -= 1
          return

    if @type is "table"
      _.extend schema,
        subquestions:
          type: [Object]
          label: "Subquestions"
          minCount: 1
          defaultValue: [{label: "Insert question here", code: new Mongo.ObjectID()._str}]
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
          defaultValue: [{code: new Mongo.ObjectID()._str}]
        'subquestions.$.minLabel':
          label: "min label"
          type: String
          optional: true
        'subquestions.$.maxLabel':
          label: "max label"
          type: String
          optional: true
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

    if finalValidation
      _.extend schema,
        _id:
          type: String
          optional: true
        questionnaireId:
          type: String
        index:
          type: Number
        createdAt:
          type: Number
          optional: true
        updatedAt:
          type: Number
          optional: true

    return schema


@Questions = new Meteor.Collection("questions",
  transform: (doc) ->
    new Question(doc)
)

Questions.before.insert BeforeInsertTimestampHook
Questions.before.update BeforeUpdateTimestampHook

Meteor.methods
  insertQuestion: (question) ->
    checkIfAdmin()

    check(question.questionnaireId, String)
    questionnaire = Questionnaires.findOne
      _id:  question.questionnaireId
    throw new Meteor.Error(400, "questionnaire #{question.questionnaireId}) not found.") unless questionnaire?

    check(question.type, String)
    delete question._id
    delete question.code

    numQuestions = Questions.find(questionnaireId: questionnaire._id).count()
    nextIndex = numQuestions+1
    if (question.index? and question.index > nextIndex) or !question.index?
      question.index = nextIndex

    q = new Question(question)
    ss = new SimpleSchema(q.getMetaSchemaDict(true))
    ss.clean(question)
    check(question, ss)

    Questions.insert question


  updateQuestion: (modifier, docId) ->
    checkIfAdmin()
    check(modifier, Object)
    check(docId, String)

    question = Questions.findOne docId
    throw new Meteor.Error(403, "question (#{docId}) not found.") unless question?

    typeChange = false
    
    #check if question.code is unique
    if (code = modifier['$set'].code) and code isnt question.code
      count = Questions.find(
        _id: $ne: question._id
        questionnaireId: question.questionnaireId
        $or: [ {code: code}, {'subquestions.code': code} ]
      ).count()
      if count > 0
        details = EJSON.stringify [ {name: "code", type: "notUnique", value: code} ]
        throw new Meteor.Error(400, "validationError", details)

    #check for dangerous changes not allowed for already answered questions
    #don't check if subquestions.$.code and choices.$.value are unique, we do that in the schema
    dangerousChange = false
    if (type=modifier['$set'].type)? and Object.keys(modifier['$set']).length is 1
      typeChange = true
      dangerousChange = true

    if (choices = modifier['$set'].choices)?
      if choices.length < question.choices.length
        dangerousChange = true
      else
        i = 0
        values = {}
        while i<choices.length
          c = choices[i]
          co = question.choices[i]
          if !c? #c was removed
            dangerousChange = true
            continue
          if co? and c.value isnt co.value #co can be null if c is being added
            dangerousChange = true
          #check if s.value is unique within this questions choices
          if values[c.value]?
            details = EJSON.stringify [ {name: "choices.#{i}.value", type: "notUnique", value: c.value} ]
            throw new Meteor.Error(400, "validationError", details)
          values[c.value] = i
          i += 1

    if (subquestions = modifier['$set'].subquestions)
      if subquestions.length < question.subquestions.length
        dangerousChange = true
      else
        i = 0
        codes = {}
        while i<subquestions.length
          s = subquestions[i]
          so = question.subquestions[i]
          if !s? #s was removed
            dangerousChange = true
            continue
          else if so? and s.code isnt so.code #so can be null if s is being added
            dangerousChange = true
          #check if s.code is unique
          #check within this questions subquestions
          if codes[s.code]?
            details = EJSON.stringify [ {name: "subquestions.#{i}.code", type: "notUnique", value: s.code} ]
            throw new Meteor.Error(400, "validationError", details)
          codes[s.code] = i
          #check within other questions of this questionnaire
          count = Questions.find(
            _id: $ne: question._id
            questionnaireId: question.questionnaireId
            $or: [ {code: s.code}, {'subquestions.code': s.code} ]
          ).count()
          if count > 0
            details = EJSON.stringify [ {name: "subquestions.#{i}.code", type: "notUnique", value: s.code} ]
            throw new Meteor.Error(400, "validationError", details)
          i += 1

    if (selectionMode=modifier['$set'].selectionMode)? and selectionMode isnt question.selectionMode
      dangerousChange = true

    if dangerousChange
      count = Answers.find(
        questionId: docId
      ).count()
      if count > 0
        throw new Meteor.Error(400, "validationErrorQuestionInUse")

    q = new Question(question).getModifiedPlainObject(modifier)
    schema = new Question(q).getMetaSchemaDict(true)
    ss = new SimpleSchema(schema)
    if typeChange
      #only the type changed: we need to clean the new object
      #to ornament it with default values
      #apply modifier
      ss.clean(q)
      check(q, ss)
      #replace question entirely
      #use direct to prevent $set.updatedAt being added
      Questions.direct.update docId, q
    else
      check(q, ss)
      Questions.update docId, modifier
    return


  moveQuestion: (questionnaireId, oldIndex, newIndex) ->
    checkIfAdmin()
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
    return


  removeQuestion: (id) ->
    checkIfAdmin()
    check(id, String)

    question = Questions.findOne id
    throw new Meteor.Error(403, "question (#{id}) not found.") unless question?
    questionnaire = Questionnaires.findOne
      _id:  question.questionnaireId
    throw new Meteor.Error(403, "questionnaire (#{question.questionnaireId}) not found.") unless questionnaire?

    #check if question is used
    count = Answers.find(
      questionId: id
    ).count()
    if count > 0
      throw new Meteor.Error(400, "validationErrorQuestionInUse")

    Questions.remove id

    #update index of remaining questions
    Questions.update
      questionnaireId: questionnaire._id
      index: { $gt: question.index }
    ,
      $inc: { index: -1 }
    ,
      multi: true
    return
