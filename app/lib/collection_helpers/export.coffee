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
          type: $ne: 'description'
        ,
          sort: {index: 1}
        ).forEach (question) ->
          #console.log question
          if question.type is 'table' or question.type is 'table_polar'
            if question.subquestions?
              question.subquestions.forEach (subquestion) ->
                if question.selectionMode is "multi"
                  question.choices.forEach (choice) ->
                    cols.push
                      title: "#{questionnaire.id}_#{subquestion.code}-#{choice.value}"
                else #if question.selectionMode is "single"
                  cols.push
                    title: "#{questionnaire.id}_#{subquestion.code}"
            else
              cols.push
                title: "#{question.code} missing subquestions (index: #{question.index} in questionnaire: #{questionnaire.title})"
          else if question.type is 'multipleChoice'
            if question.choices?
              if question.selectionMode is "multi"
                question.choices.forEach (choice) ->
                  cols.push
                    title: "#{questionnaire.id}_#{question.code}-#{choice.value}"
              else# if question.selectionMode is "single"
                cols.push
                  title: "#{questionnaire.id}_#{question.code}"
            else
              cols.push
                title: "#{questionnaire.id}_#{question.code} missing subquestions (index: #{question.index} in questionnaire: #{questionnaire.title})"
          else
            if !question.code?
              question.code = "question code missing (index: #{question.index} in questionnaire: #{questionnaire.title})"
            cols.push
              title: "#{questionnaire.id}_#{question.code}"
    cols

  @rows: (selection) ->
    rows = []
    selection.designs.forEach (design) ->
      studyDesign = StudyDesigns.findOne design._id
      #filter based on selection
      visitTemplates = studyDesign.visits.filter (visit) ->
        design.visitIds.indexOf(visit._id) > -1
      patients = Patients.find(
        _id: {$in: design.patientIds}
      ).forEach (patient) ->
        studyDesign = StudyDesigns.findOne patient.studyDesignId
        study = Studies.findOne studyDesign.studyId
        mixedVisits = __getScheduledVisitsForPatientId(patient._id)
        #filter based on selection
        mixedVisits = mixedVisits.filter (mv) ->
          id = mv.designVisitId or mv._id
          design.visitIds.indexOf(id) > -1
        visitTemplates.sort (a, b) ->
          a.index - b.index
        visitTemplates.forEach (visitTemplate) ->
          visit = Visits.findOne
            patientId: patient._id
            designVisitId: visitTemplate._id
          #we use visit in rows
          if !visit?
            visit = {}
          #ornament visit with title
          visit.title = visitTemplate.title
          #sanitise date
          if visit.date?
            visit.date = fullDate(visit.date)
          #ornament visit with dates
          scheduledVisit = mixedVisits.find (mv) ->
            id = mv.designVisitId or mv._id
            id is visitTemplate._id
          if scheduledVisit? and scheduledVisit.dateScheduled?
            visit.dateScheduled = fullDate(scheduledVisit.dateScheduled)
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
          if val?
            cols.push "#{val}"
          else
            cols.push empty

    if selection.questionnaires?
      selection.questionnaires.forEach (questionnaire) ->
        questionnaire = Questionnaires.findOne questionnaire._id
        Questions.find(
          questionnaireId: questionnaire._id
          type: $ne: 'description'
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
                        if subanswer.value.indexOf(choice.value) > -1
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
                    if answer.value.indexOf(choice.value) > -1
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
