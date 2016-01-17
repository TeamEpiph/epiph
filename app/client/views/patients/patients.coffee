Template.patients.onCreated ->
  @subscribe("studies")
  @subscribe("patients")
  @subscribe("therapists")

  tmpl = @ 
  @autorun ->
    selectedStudyIds = Session.get 'selectedStudyIds'
    if selectedStudyIds? and selectedStudyIds.length > 0
      tmpl.subscribe "studyDesignsForStudy", selectedStudyIds
    else
      tmpl.subscribe "studyDesigns"


Template.patients.rendered = ->
  @$('.selectpicker').each ->
    $(@).selectpicker()
      #actionsBox: true #only works with multiple now, nobody knows why
      #liveSearch: true
  refreshSelectValues()

Template.patients.helpers
  studies: ->
    Studies.find()

  designs: ->
    selectedStudyIds = Session.get 'selectedStudyIds'
    find = {}
    if selectedStudyIds?
      find.studyId = {$in: selectedStudyIds}
    StudyDesigns.find(find).map (design) ->
      design.study = Studies.findOne(design.studyId)
      design

  patients: ->
    selectedStudyIds = Session.get 'selectedStudyIds'
    selectedStudyDesignIds = Session.get 'selectedStudyDesignIds'
    find = {}
    if selectedStudyIds?
      find.studyId = {$in: selectedStudyIds}
    if selectedStudyDesignIds?
      find.studyDesignId = {$in: selectedStudyDesignIds}
    Patients.find(find, {sort: {studyId: 1}})

  visits: ->
    selectedStudyIds = Session.get 'selectedStudyIds'
    selectedStudyDesignIds = Session.get 'selectedStudyDesignIds'
    selectedPatientId = Session.get 'selectedPatientId'
    find = {}
    if selectedStudyIds?
      find.studyId = {$in: selectedStudyIds}
    if selectedStudyDesignIds?
      find._id = {$in: selectedStudyDesignIds}
    else if selectedPatientId?
      studyDesignId = Patients.findOne(selectedPatientId).studyDesignId
      find._id = studyDesignId
    visits = []
    StudyDesigns.find(find).forEach (design) ->
      design.visits.forEach (v) ->
        v.design = design
        v.study = Studies.findOne(design.studyId)
        visits.push v
    visits

  questionnaires: ->
    selectedPatientId = Session.get 'selectedPatientId'
    selectedDesignVisitId = Session.get 'selectedDesignVisitId'
    p = Patients.findOne selectedPatientId
    d = StudyDesigns.findOne p.studyDesignId
    v = _.find d.visits, (visit) ->
      visit._id is selectedDesignVisitId
    Questionnaires.find
      _id: {$in: v.questionnaireIds}

  singlePatient: ->
    Session.get('selectedPatientId')?

  singleVisit: ->
    Session.get('selectedPatientId')? and Session.get('selectedDesignVisitId')?

  patientsTableCursor: ->
    find = {}
    selectedStudyIds = Session.get 'selectedStudyIds'
    if selectedStudyIds?
      find.studyId = {$in: selectedStudyIds}
    selectedStudyDesignIds = Session.get 'selectedStudyDesignIds'
    if selectedStudyDesignIds?
      find.studyDesignId = {$in: selectedStudyDesignIds}
    #selectedPatientId = Session.get 'selectedPatientId'
    #if selectedPatientId?
    #  find._id = selectedPatientId
    Patients.find(find)

  patientsRTS: ->
    useFontAwesome: true
    rowsPerPage: 100
    showFilter: false
    fields: [
      key: 'id', label: "ID"
    ,
      key: 'hrid', label: "hrid"
    ,
      key: 'studyId', label: "Study", sort: true
      fn: (v,o) -> 
        study = o.study()
        return study.title if study?
    ,
      key: 'designId', label: "Design"
      fn: (v,o) -> 
        design = o.studyDesign()
        return design.title if design?
    ,
      key: 'therapistId', label: "Therapist"
      fn: (v,o) -> 
        therapist = o.therapist()
        return therapist.profile.name if therapist?
    ,
      key: '', label: "no. sheduled visits"
      fn: (v,o) -> 
        design = o.studyDesign()
        return design.visits.length if design?
    ,
      key: '', label: "no. completed visits"
      fn: (v,o) -> 
        Visits.find
          patientId: o._id
        .count()
    ,
      key: "createdAt", label: 'created', sortByValue: true
      fn: (v,o)->
        moment(v).fromNow()
    ]

  selectedPatient: ->
    Patients.findOne
      _id: Session.get('selectedPatientId')


Template.patients.events
  "change #studiesSelect": (evt) ->
    ids = $('#studiesSelect').val()
    if ids.indexOf('deselect') > -1
      $('#studiesSelect').selectpicker('deselectAll')
      ids = null
    Session.set 'selectedDesignVisitId', null
    Session.set 'selectedPatientId', null
    Session.set 'selectedStudyIds', ids
    return

  "change #designsSelect": (evt) ->
    ids = $('#designsSelect').val()
    if ids.indexOf('deselect') > -1
      $('#designsSelect').selectpicker('deselectAll')
      ids = null
    Session.set 'selectedDesignVisitId', null
    Session.set 'selectedPatientId', null
    Session.set 'selectedStudyDesignIds', ids
    return

  "change #patientSelect": (evt) ->
    id = $('#patientSelect').val()
    ids = null if id is 'deselect'
    if id is 'deselect'
      $('#patientSelect').selectpicker('deselectAll')
      id = null
    Session.set 'selectedPatientId', id
    return

  "change #visitSelect": (evt) ->
    id = $('#visitSelect').val()
    if id is 'deselect'
      $('#visitSelect').selectpicker('deselectAll')
      id = null
    Session.set 'selectedDesignVisitId', id
    return

  "change #questionnaireSelect": (evt) ->
    id = $('#questionnaireSelect').val()
    if id is 'deselect'
      $('#questionnaireSelect').selectpicker('deselectAll')
      id = null
    Session.set 'selectedQuestionnaireId', id
    return

refreshSelectValues = ->
  Meteor.setTimeout ->
    $('#studiesSelect').selectpicker('val', Session.get('selectedStudyIds'))
    $('#designsSelect').selectpicker('val', Session.get('selectedStudyDesignIds'))
    $('#patientSelect').selectpicker('val', Session.get('selectedPatientId'))
    $('#visitSelect').selectpicker('val', Session.get('selectedDesignVisitId'))
    $('#questionnaireSelect').selectpicker('val', Session.get('selectedDesignVisitId'))
  , 100
################################################
#selects rendering
studyOptionTimeout = null
refreshStudiesSelect = ->
  if studyOptionTimeout?
    Meteor.clearTimeout studyOptionTimeout
  studyOptionTimeout = Meteor.setTimeout((->
    $('#studiesSelect').selectpicker 'refresh'
    studyOptionTimeout = false
    return
  ), 50)
  return
Template.studyOption.rendered = ->
  refreshStudiesSelect()
Template.studyOption.destroyed = ->
  refreshStudiesSelect()

designOptionTimeout = null
refreshDesignsSelect = ->
  if designOptionTimeout?
    Meteor.clearTimeout designOptionTimeout
  designOptionTimeout = Meteor.setTimeout((->
    $('#designsSelect').selectpicker 'refresh'
    designOptionTimeout = false
    return
  ), 50)
  return
Template.designOption.rendered = ->
  refreshDesignsSelect()
Template.designOption.destroyed = ->
  refreshDesignsSelect()

patientOptionTimeout = null
refreshPatientsSelect = ->
  if patientOptionTimeout?
    Meteor.clearTimeout patientOptionTimeout
  patientOptionTimeout = Meteor.setTimeout((->
    $('#patientSelect').selectpicker 'refresh'
    patientOptionTimeout = false
    return
  ), 50)
  return
Template.patientOption.rendered = ->
  refreshPatientsSelect()
Template.patientOption.destroyed = ->
  refreshPatientsSelect()

visitOptionTimeout = null
refreshVisitsSelect = ->
  if visitOptionTimeout?
    Meteor.clearTimeout visitOptionTimeout
  visitOptionTimeout = Meteor.setTimeout((->
    $('#visitSelect').selectpicker 'refresh'
    visitOptionTimeout = false
    return
  ), 50)
  return
Template.visitOption.rendered = ->
  refreshVisitsSelect()
Template.visitOption.destroyed = ->
  refreshVisitsSelect()

questionnaireOptionTimeout = null
refreshQuestionnaireSelect = ->
  if questionnaireOptionTimeout?
    Meteor.clearTimeout questionnaireOptionTimeout
  questionnaireOptionTimeout = Meteor.setTimeout((->
    $('#questionnaireSelect').selectpicker 'refresh'
    questionnaireOptionTimeout = false
    return
  ), 50)
  return
Template.questionnaireOption.rendered = ->
  refreshQuestionnaireSelect()
Template.questionnaireOption.destroyed = ->
  refreshQuestionnaireSelect()

Template.visitSelect.rendered = ->
  @$('.selectpicker').each ->
    $(@).selectpicker()
Template.visitSelect.destroyed = ->
  @$('.selectpicker').each ->
    $(@).selectpicker('destroy')

Template.questionnaireSelect.rendered = ->
  @$('.selectpicker').each ->
    $(@).selectpicker()
Template.questionnaireSelect.destroyed = ->
  @$('.selectpicker').each ->
    $(@).selectpicker('destroy')

################################################
