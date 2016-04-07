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

Meteor.startup ->
  #Migrations.migrateTo('8,rerun')
  Migrations.migrateTo('latest')
