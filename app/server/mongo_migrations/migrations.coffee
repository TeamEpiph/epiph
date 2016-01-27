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
    Questionnaires.find().forEach (questionnaire) ->
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

Meteor.startup ->
  #Migrations.migrateTo('1,rerun')
  Migrations.migrateTo('latest')
