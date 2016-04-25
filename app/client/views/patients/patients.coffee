Template.patients.destroyed = ->
  $(window).off('hashchange')

Template.patients.rendered = ->
  @subscribe("studies", onReady: -> refreshSelectValues())
  @subscribe("patients", onReady: -> refreshSelectValues())
  @subscribe("therapists", onReady: -> refreshSelectValues())

  tmpl = @ 
  @autorun ->
    selectedStudyIds = Session.get 'selectedStudyIds'
    if selectedStudyIds? and selectedStudyIds.length > 0
      tmpl.subscribe "studyDesignsForStudy", selectedStudyIds, onReady: -> refreshSelectValues()
    else
      tmpl.subscribe "studyDesigns", onReady: -> refreshSelectValues()

  @$('.selectpicker').each ->
    $(@).selectpicker()
      #actionsBox: true #only works with multiple now, nobody knows why
      #liveSearch: true

  $(window).on('hashchange', hashchange)
  hashchange()

  @autorun ->
    Session.get('selectedStudyIds')
    Session.get('selectedStudyDesignIds')
    Session.get('selectedPatientId')
    Session.get('selectedDesignVisitId')
    Session.get('selectedQuestionnaireWizzard')
    refreshSelectValues()
    refreshUrlParams()


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
    if p?
      d = StudyDesigns.findOne p.studyDesignId
      if d?
        v = _.find d.visits, (visit) ->
          visit._id is selectedDesignVisitId
        return Questionnaires.find
          _id: {$in: v.questionnaireIds}
    return

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
  "click #patientsTable table tr": (evt) ->
    selectPatientId(@_id)
    return

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
    selectPatientId(id)
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

selectPatientId = (id) ->
  if id?
    patient = Patients.findOne id
    studyDesign = StudyDesigns.findOne patient.studyDesignId

    selectedStudyIds = Session.get('selectedStudyIds') or []
    selectedStudyIds.push studyDesign.studyId
    selectedStudyIds = _.unique selectedStudyIds
    Session.set 'selectedStudyIds', selectedStudyIds

    selectedStudyDesignIds = Session.get('selectedStudyDesignIds') or []
    selectedStudyDesignIds.push studyDesign._id
    selectedStudyDesignIds = _.unique selectedStudyDesignIds
    Session.set 'selectedStudyDesignIds', selectedStudyDesignIds
  Session.set 'selectedPatientId', id

refreshSelectValues = ->
  Meteor.setTimeout ->
    $('#studiesSelect').selectpicker('val', Session.get('selectedStudyIds') or null)
    $('#designsSelect').selectpicker('val', Session.get('selectedStudyDesignIds') or null)
    $('#patientSelect').selectpicker('val', Session.get('selectedPatientId') or null)
    $('#visitSelect').selectpicker('val', Session.get('selectedDesignVisitId') or null)
    $('#questionnaireSelect').selectpicker('val', Session.get('selectedQuestionnaireId') or null)
  , 100

_hashChangedInternally = false
refreshUrlParams = ->
  newHash =
    studyIds: Session.get('selectedStudyIds')
    designIds: Session.get('selectedStudyDesignIds')
    patientId: Session.get('selectedPatientId')
    visitId: Session.get('selectedDesignVisitId')
    questionnaireWizzard: Session.get('selectedQuestionnaireWizzard')
  #doesn't work because underscore is too old
  #hash = _.pick hash, (value, key, object) -> value?
  hash = {}
  Object.keys(newHash).forEach (key) ->
    value = newHash[key]
    hash[key] = value if value?
  if Object.keys(hash).length > 0
    window.location.hash = JSON.stringify hash
  else
    window.location.hash = ""
  return

hashchange = ->
  hash = window.location.hash
  if hash? and hash.length > 1
    hash = JSON.parse hash.slice(1)
    Session.set 'selectedStudyIds', hash.studyIds
    Session.set 'selectedStudyDesignIds', hash.designIds
    Session.set 'selectedPatientId', hash.patientId
    Session.set 'selectedDesignVisitId', hash.visitId
    qw = Session.get 'selectedQuestionnaireWizzard'
    if hash.questionnaireWizzard?
      if !qw?
        __showQuestionnaireWizzard hash.questionnaireWizzard
    else
      if qw?
        Modal.hide 'questionnaireWizzard'
  else
    Session.set 'selectedStudyIds', null
    Session.set 'selectedStudyDesignIds', null
    Session.set 'selectedPatientId', null
    Session.set 'selectedDesignVisitId', null
    if Session.get('selectedQuestionnaireWizzard')?
      Modal.hide 'questionnaireWizzard'
  return

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
