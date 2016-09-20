util = Npm.require('util')

Migrations.add
  version: 1
  up: ->
    console.log "delete everything except questionnaires & questions"
    Answers.remove({})
    Patients.remove({})
    Studies.remove({})
    StudyDesigns.remove({})
    Visits.remove({})

Migrations.add
  version: 2
  up: ->
    console.log "sanitize: choices variables & null values; multiplechoice modes"
    Questions.find().forEach (question) ->
      if question.choices?
        question.choices = question.choices.filter (choice) ->
          choice?
        question.choices.forEach (choice) ->
          choice.variable = choice.value
        #console.log question.choices
        Questions.update question._id,
          $set:
            choices: question.choices
      if question.type is 'multipleChoice'
        if !question.mode?
          question.mode = 'radio'
        #console.log question
        Questions.update question._id,
          $set:
            mode: question.mode

Migrations.add
  version: 3
  up: ->
    console.log "sanitize whitespaces in question.code, question.choices.variable and question.subquestions.code"
    Questionnaires.find().forEach (questionnaire) ->
      console.log questionnaire.title
      Questions.find(
        questionnaireId: questionnaire._id
      ).forEach (question) ->

        code = question.code
        if !code
          code = questionnaire.title+'_'+question.index+1
        code = code.toString()
        code = code.replace(/\s/g, '_')
        if code isnt question.code
          console.log "updating code #{question.code} -> #{code}"
          Questions.update question._id,
            $set:
              code: code

        if question.choices?
          updateChoices = false
          question.choices.forEach (choice) ->
            variable = choice.variable.toString()
            variable = variable.replace(/\s/g, '_')
            if variable.valueOf() isnt choice.variable.valueOf()
              console.log "updating variable #{choice.variable} -> #{variable}"
              choice.variable = variable
              updateChoices = true
          if updateChoices
            Questions.update question._id,
              $set:
                choices: question.choices

        if question.subquestions?
          updateSubquestions = false
          question.subquestions.forEach (subq) ->
            code = subq.code
            code = code.replace(/\s/g, '_')
            if code.valueOf() isnt subq.code.valueOf()
              console.log "updating code #{subq.code} -> #{code}"
              subq.code = code
              updateSubquestions = true
          if updateSubquestions
            Questions.update question._id,
              $set:
                subquestions: question.subquestions

Migrations.add
  version: 4
  up: ->
    console.log "fix visit titles"
    StudyDesigns.find({}).forEach (design) ->
      design.visits.forEach (v) ->
        Visits.find(
          designVisitId: v._id
        ).forEach (visit) ->
          if visit.title isnt v.title
            Visits.update visit._id,
              $set: title: v.title
    return

Migrations.add
  version: 5
  up: ->
    console.log "fix empty choices and subquestions"
    Questions.find({}).forEach (question) ->
      if question.choices?
        choices = question.choices.filter (choice) ->
          choice?
        if choices.length isnt question.choices.length
          Questions.update question._id,
            $set: choices: choices
      if question.subquestions?
        subquestions = question.subquestions.filter (subq) ->
          subq?
        if subquestions.length isnt question.subquestions.length
          console.log "fix subquestions"
          Questions.update question._id,
            $set: subquestions: subquestions
    return

Migrations.add
  version: 6
  up: ->
    console.log "fix question indices"
    Questionnaires.find().forEach (questionnaire) ->
      i = 1
      Questions.find(
        questionnaireId: questionnaire._id
      ,
        sort: index: 1
      ).forEach (question) ->
        if i isnt question.index
          console.log "fix question index"
          console.log question
          Questions.update question._id,
            $set: index: i
        i += 1
    return

Migrations.add
  version: 7
  up: ->
    console.log "migrate question.choices.$.value from Number to String"
    Questions.find().forEach (question) ->
      if question.choices?
        question.choices.forEach (choice) ->
          choice.variable = choice.variable.toString()
          choice.value = choice.value.toString()
        #console.log question.choices
        Questions.update question._id,
          $set: choices: question.choices

    Answers.find().forEach (answer) ->
      if typeof answer.value is 'object'
        updated = false
        answer.value.forEach (v) ->
          if v.checkedChoices?
            v.checkedChoices.forEach (cc) ->
              if typeof(cc.value) isnt 'string' or typeof(cc.variable) isnt 'string'
                updated = true
                cc.value = cc.value.toString()
                cc.variable = cc.variable.toString()
        if updated
          console.log(util.inspect(answer, {showHidden: false, depth: null}))
          Answers.update answer._id,
            $set: value: answer.value

Migrations.add
  version: 8
  up: ->
    console.log "init hasData for patients"
    Patients.find().forEach (patient) ->
      hasData = false
      Visits.find(
        patientId: patient._id
      ).forEach (v) ->
        c = Answers.find(
          visitId: v._id
        ).count()
        if c > 0
          hasData = true
      if hasData
        console.log patient._id+" has data!"
        Patients.update patient._id,
          $set: hasData: true
    return

Migrations.add
  version: 9
  up: ->
    console.log "remove all answers"
    Answers.remove({})
    return

Migrations.add
  version: 10
  up: ->
    console.log "remove choices.$.variable from single-selection and choices.$.value multi-selection questions"
    counter = 0
    Questions.find().forEach (q) ->
      if q.type is "multipleChoice" or q.type is "table" or q.type is "table_polar"
        #console.log q
        return if !q.choices? #invalid questions :(
        if q.mode is 'checkbox'
          q.choices.forEach (c) ->
            delete c.value
        else #if q.mode is 'radio'
          q.choices.forEach (c) ->
            delete c.variable
        #console.log q
        #console.log "\n\n\n"
        counter += Questions.update q._id,
          $set: choices: q.choices
    console.log counter+" questions updated"
    return

Migrations.add
  version: 11
  up: ->
    console.log "rename question.mode to question.selectionMode and it's values from radio to single and checkbox to multi" 
    c = 0
    Questions.find().forEach (q) ->
      if q.type is "multipleChoice" or q.type is "table" or q.type is "table_polar"
        #console.log q
        if q.mode is 'checkbox'
          q.mode = 'multi'
        else #if q.mode is 'radio'
          q.mode = 'single'
        q.selectionMode = q.mode
        delete q.mode
        #console.log q
        #console.log "\n\n\n"
        c += Questions.update q._id,
          $set: selectionMode: q.selectionMode
        Questions.update q._id,
          $unset: mode: 1
    console.log c+" questions updated"
    return

Migrations.add
  version: 12
  up: ->
    console.log "unify choices.$.variable into choice.$.value"
    counter = 0
    Questions.find().forEach (q) ->
      if q.type is "multipleChoice" or q.type is "table" or q.type is "table_polar"
        if q.selectionMode is 'multi'
          #console.log q
          q.choices.forEach (c) ->
            c.value = c.variable
            delete c.variable
          #console.log q
          #console.log "\n\n\n"
          counter += Questions.update q._id,
            $set: choices: q.choices
    console.log counter+" questions updated"
    return

Migrations.add
  version: 13
  up: ->
    console.log "fix empty subquestions"
    Questions.find({}).forEach (question) ->
      if question.subquestions?
        subquestions = question.subquestions.filter (subq) ->
          subq?
        if subquestions.length isnt question.subquestions.length
          console.log "fix subquestions"
          Questions.update question._id,
            $set: subquestions: subquestions
      else if question.type is "table" or question.type is "table_polar"
        console.log "missing subquestions for table question:"
        console.log question
        Questions.remove question._id
    return

Migrations.add
  version: 14
  up: ->
    console.log "uniquify and complement questionnaires ids"
    ids = {}
    counter = 0
    Questionnaires.find().forEach (q) ->
      if !q.id
        q.id = q.title.replace(" ", "-").trim()
        Questionnaires.update q._id,
          $set: id: q.id
      if ids[q.id]?
        counter += 1
        id = q.id+"_1"
        i = 2
        while ids[id]?
          id = id.slice(0, -(id.length-id.lastIndexOf('_')))+"_"+i
          i += 1
        ids[id] = q
        Questionnaires.update q._id,
          $set: id: id
      else
        ids[q.id] = q
    console.log counter+" questionnaires fixed"
    return

Migrations.add
  version: 15
  up: ->
    console.log "remove question.code for table questions and descriptions"
    counter = 0
    Questions.find({}).forEach (q) ->
      if (q.type is "table" or q.type is "table_polar" or q.type is "description") and q.code?
        counter += 1
        Questions.update q._id,
          $unset: code: 1
    console.log counter+" questionnaires fixed"
    return

Migrations.add
  version: 16
  up: ->
    console.log "set new question codes"
    counter = 0
    Questionnaires.find({}).forEach (qn) ->
      i = 1
      Questions.find({questionnaireId: qn._id}, {sort: {index: 1}}).forEach (q) ->
        if q.type is "table" or q.type is "table_polar"
          q.subquestions.forEach (sq) ->
            sq.code = "#{i}"
            i += 1
            counter += 1
          Questions.update q._id,
            $set: subquestions: q.subquestions
        else if q.type isnt "description"
          Questions.update q._id,
            $set: code: "#{i}"
          i += 1
          counter += 1
    console.log counter+" question codes set"
    return

Migrations.add
  version: 17
  up: ->
    console.log "clean existing questions"
    Questions.find({}).forEach (q) ->
      #question = JSON.parse(JSON.stringify(q))
      schema = new Question(q).getMetaSchemaDict(true)
      ss = new SimpleSchema(schema)
      ss.clean(q)
      check(q, ss)
      #if Object.keys(question).length isnt Object.keys(q).length
      #if question.label? and !q.label?
      #  console.log question
      #  console.log q
      #  console.log "\n\n"
      #replace question entirely
      #use direct to prevent $set.updatedAt being added
      Questions.direct.update q._id, q
    return
 
Migrations.add
  version: 18
  up: ->
    console.log "fix empty choices and subquestions"
    Questions.find({}).forEach (question) ->
      if question.choices?
        choices = question.choices.filter (choice) ->
          choice?
        if choices.length isnt question.choices.length
          Questions.update question._id,
            $set: choices: choices
      if question.subquestions?
        subquestions = question.subquestions.filter (subq) ->
          subq?
        if subquestions.length isnt question.subquestions.length
          console.log "fix subquestions"
          Questions.update question._id,
            $set: subquestions: subquestions
    return

Migrations.add
  version: 19
  up: ->
    console.log "fixing question indices..."
    counter = 0
    Questionnaires.find().forEach (questionnaire) ->
      i = 1
      Questions.find(
        questionnaireId: questionnaire._id
      ,
        sort: index: 1
      ).forEach (question) ->
        if i isnt question.index
          counter += 1
          Questions.update question._id,
            $set: index: i
        i += 1
    console.log "fixed #{counter} question indices"
    return

Migrations.add
  version: 20
  up: ->
    console.log "fixing question indices..."
    Questionnaires.find().forEach (questionnaire) ->
      i = 1
      Questions.find(
        questionnaireId: questionnaire._id
      ,
        sort: index: 1
      ).forEach (question) ->
        Questions.update question._id,
          $set: index: i
        i += 1
    console.log "fixed question indices"
    return

Migrations.add
  version: 21
  up: ->
    console.log "fixing question indices..."
    Questionnaires.find().forEach (questionnaire) ->
      i = 1
      Questions.find(
        questionnaireId: questionnaire._id
      ,
        sort: index: 1
      ).forEach (question) ->
        Questions.update question._id,
          $set: index: i
        i += 1
    console.log "fixed question indices"
    return

Migrations.add
  version: 22
  up: ->
    console.log "migrate from patient.studyDesignId to .studyDesignIds" 
    Patients.find(
      studyDesignId: $exists: 1
    ).forEach (p) ->
      console.log p
      Patients.update p._id,
        $set: studyDesignIds: [p.studyDesignId]
        $unset: studyDesignId: 1
      console.log Patients.findOne p._id
    console.log "fixed migrating studyDesignId(s)" 
    return


Meteor.startup ->
  Migrations.migrateTo('latest')
  #Migrations.migrateTo('17,rerun')
