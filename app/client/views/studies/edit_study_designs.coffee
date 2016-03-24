listQuestionnaireIds = new ReactiveVar([])
listRecordPhysicalData = new ReactiveVar(false)

remainingQuestionnaires = (design) ->
  qIds = design.questionnaireIds or []
  qIds = _.union(qIds, (listQuestionnaireIds.get() or []) )
  Questionnaires.find
    _id: {$nin: qIds}

_bloodhound = null
Template.editStudyDesignsTags.created = ->
  questionnaires = Questionnaires.find().fetch()
  questionnaires.push
    _id: "recordPhysicalData"
    title: "record physical data"
  _bloodhound = new Bloodhound(
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('title')
    queryTokenizer: Bloodhound.tokenizers.whitespace
    local: questionnaires
  )
  _bloodhound.initialize()

Template.editStudyDesignsTags.rendered = ->
  elt = @$('.tags')
  elt.tagsinput
    itemValue: '_id'
    itemText: 'title'
    typeaheadjs:
      name: 'tags'
      displayKey: 'title'
      source: _bloodhound.ttAdapter()
      allowDuplicates: true

  visit = @data.visit
  elt.tagsinput('removeAll')
  if visit.questionnaireIds? and visit.questionnaireIds.length > 0
    Questionnaires.find
      _id: {$in: visit.questionnaireIds}
    .forEach (q) ->
      elt.tagsinput 'add', q
  if visit.recordPhysicalData? and visit.recordPhysicalData
    elt.tagsinput 'add',
      _id: "recordPhysicalData"
      title: "record physical data"

_ignoreAddEvents = true
Template.editStudyDesignsTags.events =
  "itemAdded input, itemRemoved input": (evt) ->
    return if _ignoreAddEvents
    questionnaireIds = _.pluck $(evt.target).tagsinput('items'), '_id'
    recordPhysicalData = false
    questionnaireIds = _.filter questionnaireIds, (id) ->
      recordPhysicalData = true if id.valueOf() is "recordPhysicalData"
      id.valueOf() isnt "recordPhysicalData"
    Meteor.call "scheduleQuestionnairesAtVisit", @design._id, @visit._id, questionnaireIds, (error) ->
      throwError error if error?
    if @visit.recordPhysicalData isnt recordPhysicalData
      Meteor.call "scheduleRecordPhysicalDataAtVisit", @design._id, @visit._id, recordPhysicalData, (error) ->
        throwError error if error?
    return

Template.editStudyDesigns.rendered = ->
  _ignoreAddEvents = false
  Meteor.setTimeout ->
    $("button.accordion-toggle").first().click()
  , 400

Template.editStudyDesigns.helpers
  designs: ->
    StudyDesigns.find studyId: @_id,
      sort: {createdAt: 1}

  #this design=design
  titleEO: ->
    design = @design
    value: design.title
    emptytext: "no title"
    success: (response, newVal) ->
      StudyDesigns.update design._id,
        $set: {title: newVal}
      return

  #this design=design
  hasRemainingQuestionnaires: ->
    remainingQuestionnaires(@design).count()

  #this design=design
  remainingQuestionnaires: ->
    remainingQuestionnaires(@design)

  #this design=design
  questionnaires: ->
    qIds = @design.questionnaireIds or []
    qIds = _.union(qIds, (listQuestionnaireIds.get() or []) )
    Questionnaires.find
      _id: {$in: qIds}

  listRecordPhysicalData: ->
    @design.recordPhysicalData || listRecordPhysicalData.get()

  #this design=design
  visits: ->
    @design.visits.sort (a, b)->
      a.index - b.index
    prevDay = 0
    #augment visits
    #http://stackoverflow.com/questions/13789622/accessing-parent-context-in-meteor-templates-and-template-helpers
    @design.visits.map (v)->
      if v.day?
        daysBetween = v.day-prevDay
        _.extend v,
          daysBetween: daysBetween
        prevDay = v.day
        if daysBetween is 0
          delete v.daysBetween
      v

  #this visit design
  visitQuestionnaires: ->
    #Questionnaires.find
    #  _id: {$in: @visit.questionnaireIds}
    @visit.questionnaireIds

  #this visit design
  visitTitleEO: ->
    visit = @visit
    design = @design
    value: visit.title
    emptytext: "no title"
    success: (response, newVal) ->
      dv = design.visits.find (v) ->
        v.title is newVal
      if dv?
        return "a visit with this title already exists."
      Meteor.call "changeStudyDesignVisitTitle", design._id, visit._id, newVal, (error) ->
        throwError error if error?
      return

  #this visit design
  visitDayEO: ->
    visit = @visit
    design = @design
    value: visit.day
    emptytext: "no day set"
    success: (response, newVal) ->
      dv = design.visits.find (v) ->
        parseInt(v.day) is parseInt(newVal)
      if dv?
        return "a visit already exists on this day!"
      Meteor.call "changeStudyDesignVisitDay", design._id, visit._id, newVal, (error) ->
        throwError error if error?
      return


  #this design:StudyDesign visit:StudyDesign.visit questionnaire:Questionnaire
  questionnaireIconClass: ->
    questionnaire = @questionnaire
    found = false
    if @visit.questionnaireIds
      _.some @visit.questionnaireIds, (qId)->
        found = qId is questionnaire._id
        found
    if found
      return "fa-check-square-o brand-primary"
    else
      return "fa-square-o hoverOpaqueExtreme"

  #this design:StudyDesign visit:StudyDesign.visit
  physicalIconClass: ->
    if @visit.recordPhysicalData? and @visit.recordPhysicalData
      return "fa-check-square-o brand-primary"
    else
      return "fa-square-o hoverOpaqueExtreme"


Template.editStudyDesigns.events
  "click .editable-click": (evt) ->
    evt.preventDefault()
    evt.stopPropagation()

  "click #createStudyDesign": (evt) ->
    Meteor.call "createStudyDesign", @_id, (error, studyDesignId) ->
      throwError error if error?

  "click .removeDesign": (evt) ->
    evt.preventDefault()
    designId = @design._id
    swal {
      title: 'Are you sure?'
      text: 'Do you really want to delete this design?'
      type: 'warning'
      showCancelButton: true
      confirmButtonText: 'Yes'
    }, ->
      Meteor.call "removeStudyDesign", designId, (error) ->
        throwError error if error?
      return
    return false

  "click #addVisit": (evt) ->
    evt.preventDefault()
    Meteor.call "addStudyDesignVisit", @design._id, (error) ->
      throwError error if error?

  "click .listQuestionnaire": (evt) ->
    evt.preventDefault()
    questionnaireId = $(evt.target).data("id")
    qIds = listQuestionnaireIds.get() or []
    qIds.push questionnaireId
    listQuestionnaireIds.set qIds

  "click .listRecordPhysicalData": (evt) ->
    evt.preventDefault()
    listRecordPhysicalData.set !listRecordPhysicalData.get()

  #"click .toggleQuestionnaireAtVisit": (evt) ->
  #  evt.preventDefault()
  #  doSchedule = not $(evt.target).hasClass('fa-check-square-o') #isChecked 
  #  questionnaireIds = @visit.questionnaireIds || []
  #  questionnaire = @questionnaire
  #  if doSchedule
  #    questionnaireIds.push questionnaire._id
  #    $("input.tags[data-visit-id=#{@visit._id}]").tagsinput('add', questionnaire) 
  #  else
  #    questionnaireIds = _.filter questionnaireIds, (qId)->
  #      qId isnt questionnaire._id
  #    $("input.tags[data-visit-id=#{@visit._id}]").tagsinput('remove', questionnaire) 
  #  Meteor.call "scheduleQuestionnairesAtVisit", @design._id, @visit._id, questionnaireIds, (error) ->
  #    throwError error if error?

  #"click .toggleRecordPhysicalDataAtVisit": (evt) ->
  #  evt.preventDefault()
  #  Meteor.call "scheduleRecordPhysicalDataAtVisit", @design._id, @visit._id, !@visit.recordPhysicalData, (error) ->
  #    throwError error if error?

  "click .moveUp": (evt) ->
    Meteor.call "moveStudyDesignVisit", @design._id, @visit._id, true, (error) ->
      throwError error if error?

  "click .moveDown": (evt) ->
    Meteor.call "moveStudyDesignVisit", @design._id, @visit._id, false, (error) ->
      throwError error if error?

  "click .removeVisit": (evt) ->
    evt.preventDefault()
    designId = @design._id
    visitId = @visit._id
    swal {
      title: 'Are you sure?'
      text: 'Do you really want to delete this visit?'
      type: 'warning'
      showCancelButton: true
      confirmButtonText: 'Yes'
    }, ->
      Meteor.call "removeStudyDesignVisit", designId, visitId, (error) ->
        throwError error if error?
      return
    return false
