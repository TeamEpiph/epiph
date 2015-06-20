Template.editStudy.rendered = ->
  params = Router.current().params
  if !params.page
    Router.go "editStudy",
      _id: @data._id
      page: "editStudyPatients"
    
  
Template.editStudy.helpers
  pages: ->
    [
      title: "Designs"
      aID: "goToDesigns"
      template: "editStudyDesigns"
    ,
      title: "Patients"
      aID: "goToPatients"
      template: "editStudyPatients"
    ]

  #this page
  pageTabClasses: ->
    params = Router.current().params
    return "" if !params? or !params.page?
    if @template is params.page
      return "active"
    ""

  template: ->
    Router.current().params.page
    
    
Template.editStudy.events
  "click #goToDesigns": (evt) ->
    _id = $(evt.target).data('id')
    Router.go "editStudy",
      _id: _id
      page: "editStudyDesigns"
    false
  "click #goToPatients": (evt) ->
    _id = $(evt.target).data('id')
    Router.go "editStudy",
      _id: _id
      page: "editStudyPatients"
    false



AutoForm.hooks
  editSessionPatientsForm:
    onSubmit: (insertDoc, updateDoc, currentDoc) ->
      Session.get('editingPatientIds').forEach (id) ->
        Patients.update _id: id, updateDoc
      @done()
      false

Template.editStudyPatients.rendered = ->
  Session.set('editingPatientIds', null)

Template.editStudyPatients.helpers
  patients: ->
    Patients.find
      studyId: @_id

  patientsRTS: ->
    useFontAwesome: true,
    rowsPerPage: 100,
    showFilter: true,
    fields: [
      { key: 'id', label: "", fn: (v, o) -> new Spacebars.SafeString("<input type='checkbox' />") },
      { key: 'id', label: "ID" },
      { key: 'hrid', label: "HRID" },
      { key: 'key', label: "Key", sort: 'descending'},
      { key: 'designId', label: "Design" },
      { key: 'therapistId', label: "Therapist", fn: (v,o) -> therapist = o.therapist(); return therapist.profile.name if therapist? },
      { key: "createdAt", label: 'created', sortByValue: true, fn: (v,o)->moment(v).fromNow() },
      { key: 'buttons', label: '', tmpl: Template.studyPatientsTableButtons }
    ]


  editingPanelTitle: ->
    ids = Session.get('editingPatientIds')
    return "Patient editor" if !ids? or ids.length is 0
    if ids.length > 1
      "edit #{ids.length} patients"
    else
      p = Patients.findOne _id: ids[0]
      "edit patient: #{p.id}"

  numPatientsEditing: ->
    ids = Session.get('editingPatientIds')
    return ids.length if ids?
    false

  formDoc: ->
    ids = Session.get('editingPatientIds')
    if !ids? or ids.length is 0 or ids.length > 1
      null
    else
      Patients.findOne _id: ids[0]
    
  editSessionPatientsSchema: ->
    therapists = Meteor.users.find(
      roles: "therapist"
    ).map (t) ->
      label: t.profile.name
      value: t._id
    schema =
      therapistId:
        label: "Therapist"
        type: String
        autoform:
          type: "select"
          options: therapists
    ids = Session.get('editingPatientIds')
    if ids? and ids.length is 1
      schema = _.extend schema, 
        key:
          label: "Key"
          type: String
          optional: true
    new SimpleSchema(schema)

Template.editStudyPatients.events
  "click #createPatient": (evt) ->
    Meteor.call "createPatient", @_id, (error, patientId) ->
      throwError error if error?

  "click .reactive-table tr": (evt) ->
    if event.target.type is "checkbox"
      editingPatientIds = Session.get("editingPatientIds") or []
      if $(event.target).is(":checked")
        editingPatientIds.push @_id
      else
        index = editingPatientIds.indexOf @_id
        editingPatientIds.splice(index, 1)
      Session.set "editingPatientIds", _.uniq editingPatientIds
    
  "click button.show": (evt) ->
    patientId = @_id
    openPatientIds = Session.get("openPatientIds") or []
    openPatientIds.push patientId
    openPatientIds = _.uniq openPatientIds
    Session.set "openPatientIds", openPatientIds
    Session.set "selectedPatientId", patientId
    Router.go "patients"
