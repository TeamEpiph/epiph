_refreshSelectsContentsTrigger = new ReactiveVar(false)

Template.patients.destroyed = ->
  $(window).off('hashchange')

Template.patients.rendered = ->
  @subscribe("studies", onReady: -> refreshSelectValues())
  @subscribe("patients", onReady: -> refreshSelectValues())
  @subscribe("caseManagers", onReady: -> refreshSelectValues())
  @subscribe("studyDesigns", onReady: -> refreshSelectValues())

  @$('.selectpicker').each ->
    $(@).selectpicker()
      #actionsBox: true #only works with multiple now, nobody knows why
      #liveSearch: true

  $(window).on('hashchange', hashchange)

  @autorun ->
    Session.get('selectedStudyIds')
    #Session.get('selectedStudyDesignIds')
    Session.get('selectedPatientId')
    Session.get('selectedDesignVisitId')
    Session.get('selectedQuestionnaireWizzard')
    refreshSelectValues()
    refreshUrlParams()


Template.patients.helpers
  studies: ->
    Studies.find({}, {sort: title: 1})

  designs: ->
    selectedStudyIds = Session.get 'selectedStudyIds'
    find = {}
    if selectedStudyIds?
      find.studyId = {$in: selectedStudyIds}
    StudyDesigns.find(find, {sort: index: 1}).map (design) ->
      design.study = Studies.findOne(design.studyId)
      design

  patients: ->
    _refreshSelectsContentsTrigger.get()
    selectedStudyIds = Session.get 'selectedStudyIds'
    #selectedStudyDesignIds = Session.get 'selectedStudyDesignIds'
    selectedPatientId = Session.get 'selectedPatientId'
    find = {}
    if selectedStudyIds? and selectedStudyIds.length > 0
      find.studyId = {$in: selectedStudyIds}
    #if selectedStudyDesignIds? and selectedStudyDesignIds.length > 0
    #  find.studyDesignIds = {$in: selectedStudyDesignIds}
    if !find.studyId? and !find.studyDesignId? and selectedPatientId?
      find._id = selectedPatientId
    Patients.find(find, {sort: {studyId: 1}})

  visits: ->
    selectedStudyIds = Session.get 'selectedStudyIds'
    #selectedStudyDesignIds = Session.get 'selectedStudyDesignIds'
    selectedPatientId = Session.get 'selectedPatientId'
    find = {}
    if selectedStudyIds?
      find.studyId = {$in: selectedStudyIds}
    #if selectedStudyDesignIds?
    #  find._id = {$in: selectedStudyDesignIds}
    if selectedPatientId?
      studyDesignIds = Patients.findOne(selectedPatientId).studyDesignIds
      find._id = {$in: studyDesignIds}
    visits = []
    StudyDesigns.find(find, sort: {title: 1}).forEach (design) ->
      study = Studies.findOne(design.studyId)
      design.visits.forEach (v) ->
        v.design = design
        v.study = study
        visits.push v
    visits

  questionnaires: ->
    selectedPatientId = Session.get 'selectedPatientId'
    selectedDesignVisitId = Session.get 'selectedDesignVisitId'
    p = Patients.findOne selectedPatientId
    if p?
      questionnaireIds = []
      visit = null
      StudyDesigns.find(
        _id: $in: p.studyDesignIds
      ).forEach (d) ->
        v = _.find d.visits, (visit) ->
          visit._id is selectedDesignVisitId
        if v? and v.length > 0
          visit = v[0]
      if visit?
        return Questionnaires.find
          _id: {$in: v.questionnaireIds}
        ,
          sort: title: 1
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
    #selectedStudyDesignIds = Session.get 'selectedStudyDesignIds'
    #if selectedStudyDesignIds?
    #  find.studyDesignIds = {$in: selectedStudyDesignIds}
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
      key: 'studyId', label: "Study", sortOrder: 0
      fn: (v,o) ->
        study = o.study()
        return study.title if study?
    ,
      key: 'studyDesignIds', label: "Designs"
      fn: (v,o) ->
        ds = ""
        designs = o.studyDesigns().forEach (d) ->
          ds += d.title+', '
        return ds.slice(0, -2)
    ,
      key: 'caseManagerId', label: "Case Manager"
      fn: (v,o) ->
        caseManager = o.caseManager()
        if caseManager?
          getUserDescription caseManager
        else
          ""
    ,
      key: 'languages', label: "Languages"
      fn: (v,o) ->
        o.languages()
    ,
      key: '', label: "no. sheduled visits"
      fn: (v,o) ->
        visits = 0
        design = o.studyDesigns().forEach (d) ->
          visits += d.visits.length if d?
        return visits
    ,
      key: "createdAt", label: 'created', sortByValue: true
      fn: (v,o)-> fullDate(v)
    ]

  selectedPatient: ->
    Patients.findOne
      _id: Session.get('selectedPatientId')


Template.patients.events
  "click #patientsTable table tr": (evt) ->
    return if !@_id #header
    selectPatientId(@_id)
    return

  "change #studiesSelect": (evt) ->
    ids = $('#studiesSelect').val()
    if !ids? or ids.indexOf('deselect') > -1
      $('#studiesSelect').selectpicker('deselectAll')
      ids = null
    Session.set 'selectedDesignVisitId', null
    Session.set 'selectedPatientId', null
    Session.set 'selectedStudyIds', ids
    return

  #"change #designsSelect": (evt) ->
  #  ids = $('#designsSelect').val()
  #  if ids.indexOf('deselect') > -1
  #    $('#designsSelect').selectpicker('deselectAll')
  #    ids = null
  #  Session.set 'selectedDesignVisitId', null
  #  Session.set 'selectedPatientId', null
  #  Session.set 'selectedStudyDesignIds', ids
  #  return

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

@selectPatientId = (id, clearVisitsSelection) ->
  if id?
    patient = Patients.findOne id
    if patient.studyDesignIds?
      # we can use the first designId here because all designs
      # must be in the same studyDesign
      studyDesign = StudyDesigns.findOne patient.studyDesignIds[0]

      if studyDesign?
        selectedStudyIds = Session.get('selectedStudyIds') or []
        selectedStudyIds.push studyDesign.studyId
        selectedStudyIds = _.unique selectedStudyIds
        Session.set 'selectedStudyIds', selectedStudyIds

      #check if selectedDesignVisitId is posible for patient
      selectedDesignVisitId = Session.get 'selectedDesignVisitId'
      if selectedDesignVisitId?
        sd = StudyDesigns.findOne
          _id: $in: patient.studyDesignIds
          'visits._id': selectedDesignVisitId
        if !sd #selectedDesignVisitId is from another design, which this patient isn't part of
          Session.set 'selectedDesignVisitId', null

      #selectedStudyDesignIds = Session.get('selectedStudyDesignIds') or []
      #StudyDesigns.find(_id: $in: patient.studyDesignIds).forEach (d) ->
      #  selectedStudyDesignIds.push d._id
      #selectedStudyDesignIds = _.unique selectedStudyDesignIds
      #Session.set 'selectedStudyDesignIds', selectedStudyDesignIds
    else
      Session.set 'selectedStudyIds', null
      #Session.set 'selectedStudyDesignIds', null
  if clearVisitsSelection
    Session.set 'selectedDesignVisitId', null
  Session.set 'selectedPatientId', id
  return

refreshSelectValues = ->
  _refreshSelectsContentsTrigger.set(_refreshSelectsContentsTrigger.get())
  Meteor.setTimeout ->
    $('#studiesSelect').selectpicker('val', Session.get('selectedStudyIds') or null)
    #$('#designsSelect').selectpicker('val', Session.get('selectedStudyDesignIds') or null)
    $('#patientSelect').selectpicker('val', Session.get('selectedPatientId') or null)
    $('#visitSelect').selectpicker('val', Session.get('selectedDesignVisitId') or null)
    $('#questionnaireSelect').selectpicker('val', Session.get('selectedQuestionnaireId') or null)
  , 100

_hashChangedInternally = false
refreshUrlParams = ->
  newHash =
    studyIds: Session.get('selectedStudyIds')
    #designIds: Session.get('selectedStudyDesignIds')
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
    error = null
    #TODO fix decodeURI in safari
    try
      hash = decodeURI(hash)
    catch e
      console.log "decodeURI error:"
      console.log e
      error = e
    return if error?
    hash = JSON.parse hash.slice(1)
    Session.set 'selectedStudyIds', hash.studyIds
    #Session.set 'selectedStudyDesignIds', hash.designIds
    Session.set 'selectedPatientId', hash.patientId
    Session.set 'selectedDesignVisitId', hash.visitId
    qw = Session.get 'selectedQuestionnaireWizzard'
    if hash.questionnaireWizzard?
      if !qw?
        __showQuestionnaireWizzard hash.questionnaireWizzard
    else
      if qw?
        __closeQuestionnaireWizzard()
  else
    Session.set 'selectedStudyIds', null
    #Session.set 'selectedStudyDesignIds', null
    Session.set 'selectedPatientId', null
    Session.set 'selectedDesignVisitId', null
    if Session.get('selectedQuestionnaireWizzard')?
      __closeQuestionnaireWizzard()
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

#designOptionTimeout = null
#refreshDesignsSelect = ->
#  if designOptionTimeout?
#    Meteor.clearTimeout designOptionTimeout
#  designOptionTimeout = Meteor.setTimeout((->
#    $('#designsSelect').selectpicker 'refresh'
#    designOptionTimeout = false
#    return
#  ), 50)
#  return
#Template.designOption.rendered = ->
#  refreshDesignsSelect()
#Template.designOption.destroyed = ->
#  refreshDesignsSelect()

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
Template.patientOption.helpers
  studyDesignTitles: ->
    titles = ""
    @studyDesigns().forEach (d) ->
      titles +=d.title+', '
    titles.slice(0, -2)

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
