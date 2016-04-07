class @Export
  @columnHeaders: (selection) ->
    cols = []
    if selection.system?
      Object.keys(selection.system).forEach (entity) ->
        variables = selection.system[entity]
        variables.forEach (variable) ->
          cols.push
            title: "#{entity}.#{variable}"
      
    if selection.questionnaires?
      selection.questionnaires.forEach (questionnaire) ->
        questionnaire = Questionnaires.findOne questionnaire._id
        Questions.find(
          questionnaireId: questionnaire._id
        ,
          sort: {index: 1}
        ).forEach (question) ->
          #console.log question
          if !question.code?
            question.code = "question code missing (index: #{question.index} in questionnaire: #{questionnaire.title})"
          if question.type is 'table' or question.type is 'table_polar'
            if question.subquestions?
              question.subquestions.forEach (subquestion) ->
                if question.selectionMode is "multi"
                  question.choices.forEach (choice) ->
                    cols.push
                      title: "#{subquestion.code}-#{choice.variable}"
                else #if question.selectionMode is "single"
                  cols.push
                    title: "#{subquestion.code}"
            else
              cols.push
                title: "#{question.code} missing subquestions (index: #{question.index} in questionnaire: #{questionnaire.title})"
          else if question.type is 'multipleChoice'
            if question.choices?
              if question.selectionMode is "multi"
                question.choices.forEach (choice) ->
                  cols.push
                    title: "#{question.code}-#{choice.variable}"
              else# if question.selectionMode is "single"
                cols.push
                  title: "#{question.code}"
            else
              cols.push
                title: "#{question.code} missing subquestions (index: #{question.index} in questionnaire: #{questionnaire.title})"
          else
            cols.push
              title: "#{question.code}"
    cols

  @rows: (selection) ->
    rows = []
    selection.designs.forEach (design) ->
      studyDesign = StudyDesigns.findOne
        _id: design._id
      visitTemplates = studyDesign.visits.filter (visit) ->
        design.visitIds.indexOf(visit._id) > -1
      patients = Patients.find(
        _id: {$in: design.patientIds}
      ).forEach (patient) ->
        studyDesign = StudyDesigns.findOne patient.studyDesignId
        study = Studies.findOne studyDesign.studyId
        visitTemplates.forEach (visitTemplate) ->
          visit = Visits.findOne
            patientId: patient._id
            designVisitId: visitTemplate._id
          rows.push
            study: study
            studyDesign: studyDesign
            patient: patient
            visitTemplate: visitTemplate
            visit: visit
    rows

  @columns: (selection, row) ->
    cols = []
    empty = 'NA'
    if Meteor.isClient
      empty = 'only in CSV'
    error = 'ERROR'
    if selection.system?
      Object.keys(selection.system).forEach (entity) ->
        variables = selection.system[entity]
        variables.forEach (variable) ->
          if row[entity]?
            if typeof row[entity][variable] is 'function'
              val = row[entity][variable]()
            else
              val = row[entity][variable]
          else
            val = empty#"#{entity}.#{variable}"
          cols.push "#{val}"

    if selection.questionnaires?
      selection.questionnaires.forEach (questionnaire) ->
        questionnaire = Questionnaires.findOne questionnaire._id
        Questions.find(
          questionnaireId: questionnaire._id
        ,
          sort: {index: 1}
        ).forEach (question) ->
          answer = Answers.findOne
            questionId: question._id
            visitId: row.visit._id if row.visit?
          if question.type is 'table' or question.type is 'table_polar'
            if question.subquestions? and question.subquestions.length > 0
              question.subquestions.forEach (subquestion) ->
                if answer? and answer.value.length > 0
                  subanswer = answer.value.find (v) ->
                    v.code is subquestion.code
                  if question.selectionMode is "multi"
                    question.choices.forEach (choice) ->
                      if subanswer?
                        if subanswer.value.indexOf(choice.variable) > -1
                          cols.push 1
                        else
                          cols.push 0
                      else #no subanswer for this question
                        cols.push empty
                  else #if question.selectionMode is "single"
                    if subanswer? and subanswer.value?
                      cols.push subanswer.value
                    else #no subanswer for this subquestion
                      cols.push empty
                else #no answer for this question
                  if question.selectionMode is "multi"
                    question.choices.forEach (choice) ->
                      cols.push empty
                  else #if question.selectionMode is "single"
                    cols.push empty
            else #missing subquestions
              if Meteor.isServer
                cols.push error
              else
                cols.push "#{question.code} missing subquestions (index: #{question.index} in questionnaire: #{questionnaire.title})"
          else if question.type is 'multipleChoice'
            if question.choices?
              if question.selectionMode is "multi"
                question.choices.forEach (choice) ->
                  if answer?
                    if answer.value.indexOf(choice.variable) > -1
                      cols.push 1
                    else
                      cols.push 0
                  else
                    cols.push empty
              else #if question.selectionMode is "single"
                if answer?
                  cols.push answer.value
                else
                  cols.push empty
            else
              if Meteor.isServer
                cols.push error
              else
                cols.push "#{question.code} missing subquestions (index: #{question.index} in questionnaire: #{questionnaire.title})"
          else #all other question types
            if answer?
              cols.push answer.value
            else
              cols.push empty
    cols
