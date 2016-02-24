_studyIcon = 'fa fa-book'
_designIcon = 'fa fa-list-alt'
_visitIcon = 'fa fa-calendar-check-o'
_patientIcon = 'fa fa-user'
_questionnaireIcon = 'fa fa-file-text-o' 
_questionIcon = 'fa fa-cube'
Template.export.rendered = ->
  # nodes are leafes in the export tree
  # node id nomenclatura:
  #   - ids beginning with 1 underscore are structure only (folders) and ignored 
  #   - ids beginning with 2 underscore are system variables selectors (regexed)
  #   - ids not beginning with an underscore are content (visit, patient, etc.)
  nodes = []
  nodes.push
    id: '_systemVariables'
    parent: '#'
    text: 'System Variables'
    icon: 'fa fa-gear'
    state: { opened: true }

  nodes.push
    id: '_patient'
    parent: '_systemVariables'
    text: 'Patient'
    icon: _patientIcon
    state: { opened: true }
  nodes.push
    id: '__patient.id'
    parent: '_patient'
    text: 'patient ID'
    icon: _patientIcon
    state: { selected: true, disabled: true }
  nodes.push
    id: '__patient.hrid'
    parent: '_patient'
    text: 'patient HRID'
    icon: _patientIcon
  nodes.push
    id: '__patient._id'
    parent: '_patient'
    text: 'internal ID'
    icon: _patientIcon
  nodes.push
    id: '__patient.therapistName'
    parent: '_patient'
    text: 'case manager'
    icon: _patientIcon

  nodes.push
    id: '_study'
    parent: '_systemVariables'
    text: 'Study'
    icon: _studyIcon
    state: { opened: true }
  nodes.push
    id: '__study.title'
    parent: '_study'
    text: 'title'
    icon: _studyIcon

  nodes.push
    id: '_studyDesign'
    parent: '_systemVariables'
    text: 'Study Design'
    icon: _designIcon
    state: { opened: true }
  nodes.push
    id: '__studyDesign.title'
    parent: '_studyDesign'
    text: 'title'
    icon: _designIcon

  nodes.push
    id: '_visit'
    parent: '_systemVariables'
    text: 'Visit'
    icon: _visitIcon
    state: { opened: true }
  nodes.push
    id: '__visitTemplate.title'
    parent: '_visit'
    text: 'title'
    icon: _visitIcon
    state: { selected: true, disabled: true }

  nodes.push
    id: '_studies'
    parent: '#'
    text: 'Studies'
    icon: _studyIcon
    state: { opened: true }

  Studies.find().forEach (study) ->
    studyNode =
      id: 'study_'+study._id
      parent: '_studies'
      text: study.title
      icon: _studyIcon
      state: { opened: true }
    nodes.push studyNode

    StudyDesigns.find(
      studyId: study._id
    ).forEach (design) ->
      nodes.push
        id: 'design_'+design._id
        parent: 'study_'+study._id
        text: design.title
        icon: _designIcon
        state:
          opened: false

      nodes.push
        id: '_patients_'+design._id
        parent: 'design_'+design._id
        text: 'Patients'
        icon: _patientIcon
        state:
          opened: true
      nodes.push
        id: '_visits_'+design._id
        parent: 'design_'+design._id
        text: 'Visits'
        icon: _visitIcon
        state:
          opened: true
      nodes.push
        id: '_questionnaires_'+design._id
        parent: 'design_'+design._id
        text: 'Questionnaires'
        icon: _questionnaireIcon
        state:
          opened: true

      Patients.find(
        studyDesignId: design._id
      ).forEach (patient) ->
        title = patient.id
        if patient.hrid
          title += " - "+patient.hrid
        nodes.push
          id: 'patient_'+patient._id
          parent: '_patients_'+design._id
          text: title
          icon: _patientIcon
          state:
            opened: true

      design.visits.forEach (visit) ->
        nodes.push
          id: 'visit_'+visit._id
          parent: '_visits_'+design._id
          text: visit.title
          icon: _visitIcon
          state:
            opened: true

      questionnaireIds = design.questionnaireIds || []
      Questionnaires.find(
        _id: {$in: questionnaireIds}
      ).forEach (questionnaire) ->
        nodes.push
          id: 'questionnaire_'+questionnaire._id+'_'+design._id
          parent: '_questionnaires_'+design._id
          text: questionnaire.title
          icon: _questionnaireIcon
          state:
            opened: false

        Questions.find(
          questionnaireId: questionnaire._id
        ,
          sort: {index: 1}
        ).forEach (question) ->
          title = "#{question.index} - #{question.label}"
          nodes.push
            id: 'question_'+question._id+'_'+design._id
            parent: 'questionnaire_'+questionnaire._id+'_'+design._id
            text: title
            icon: _questionIcon


  #console.log nodes
  $('#tree').jstree(
    plugins: [ "checkbox" ]
    checkbox:
      "keep_selected_style": false
    core:
      data: nodes
      themes:
        name: 'proton'
        responsive: true
  ).on 'changed.jstree', (evt, data) ->
    selectedIds = data.instance.get_selected()

    #dicts for easier searching
    systemVariables = {}
    patientsAndVisitsByDesignsDict = {}
    questionnairesAndQuestionsDict = {}

    selectedIds.forEach (sId) ->
      #system variables
      if sId.lastIndexOf("__", 0) is 0
        regex = /__(.+?)\.(.+)/
        match = regex.exec sId
        entity = match[1]
        variable = match[2]
        e = systemVariables[entity] || []
        #e[variable] = true
        e.push variable
        systemVariables[entity] = e

      #content
      else if sId.lastIndexOf("patient_", 0) is 0 or
      sId.lastIndexOf("visit_", 0) is 0 or
      sId.lastIndexOf("question_", 0) is 0

        path = data.instance.get_path(sId, false, true)
        #remove "folders"
        path = path.filter (pId) ->
          pId.substring(0, 1) isnt '_'
        #console.log path

        if sId.lastIndexOf("patient_", 0) is 0
          designId = null
          patientId = null
          path.forEach (step) ->
            if step.lastIndexOf("design_", 0) is 0
              designId = step.replace "design_", ""
            if step.lastIndexOf("patient_", 0) is 0
              patientId = step.replace "patient_", ""
          debugger if !designId? or !patientId?
          design = patientsAndVisitsByDesignsDict[designId]
          if !design?
            design =
              _id: designId
              patientIds: [patientId]
              visitIds: []
          else
            design.patientIds.push patientId
            design.patientIds = _.unique design.patientIds
          patientsAndVisitsByDesignsDict[designId] = design

        else if sId.lastIndexOf("visit_", 0) is 0
          designId = null
          visitId = null
          path.forEach (step) ->
            if step.lastIndexOf("design_", 0) is 0
              designId = step.replace "design_", ""
            if step.lastIndexOf("visit_", 0) is 0
              visitId = step.replace "visit_", ""
          debugger if !designId? or !visitId?
          design = patientsAndVisitsByDesignsDict[designId]
          if !design?
            design =
              _id: designId
              patientIds: []
              visitIds: [visitId]
          else
            design.visitIds.push visitId
            design.visitIds = _.unique design.visitIds
          patientsAndVisitsByDesignsDict[designId] = design

        else if sId.lastIndexOf("question_", 0) is 0
          questionnaireId = null
          questionId = null
          path.forEach (step) ->
            if step.lastIndexOf("questionnaire_", 0) is 0
              questionnaireId = step.replace "questionnaire_", ""
              questionnaireId = questionnaireId.replace(/_.*/, '')
            if step.lastIndexOf("question_", 0) is 0
              questionId = step.replace "question_", ""
          debugger if !questionnaireId? or !questionId?
          questionnaire = questionnairesAndQuestionsDict[questionnaireId]
          if !questionnaire?
            questionnaire =
              _id: questionnaireId
              questionIds: [questionId]
          else
            questionnaire.questionIds.push questionId
            questionnaire.questionIds = _.unique questionnaire.questionIds
          questionnairesAndQuestionsDict[questionnaireId] = questionnaire

    #convert dicts to arrays
    designs = []
    for key in Object.keys(patientsAndVisitsByDesignsDict)
      designs.push patientsAndVisitsByDesignsDict[key]
    questionnaires = []
    for key in Object.keys(questionnairesAndQuestionsDict)
      questionnaires.push questionnairesAndQuestionsDict[key]

    selection =
      system: systemVariables
      designs: designs
      questionnaires: questionnaires

    console.log selection
    _selection.set selection

    return

_selection = new ReactiveVar []
_waitingForDownload = new ReactiveVar false

Template.export.helpers
  columnHeaders: ->
    selection = _selection.get()
    Export.columnHeaders(selection)

  #rows: ->
  #  selection = _selection.get()
  #  return if not selection.designs?
  #  Export.rows(selection)

  #columns: ->
  #  row = @
  #  Tracker.nonreactive ->
  #    selection = _selection.get()
  #    Export.columns(selection, row)

  waitingForDownload: ->
    _waitingForDownload.get()

Template.export.events
  'click #downloadCSV': (evt) ->
    _waitingForDownload.set true
    selection = _selection.get()
    loginToken = Accounts._storedLoginToken()
    Meteor.call 'createCSV', selection, loginToken, (error, url) ->
      _waitingForDownload.set false
      throwError error if error?
      window.open url#, '_blank'
