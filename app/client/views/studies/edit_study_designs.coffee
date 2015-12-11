listQuestionnaireIds = new ReactiveVar([])
listRecordPhysicalData = new ReactiveVar(false)

remainingQuestionnaires = (design) ->
  qIds = design.questionnaireIds or []
  qIds = _.union(qIds, (listQuestionnaireIds.get() or []) )
  Questionnaires.find
    _id: {$nin: qIds}


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
  visitTitleEO: ->
    visit = @visit
    design = @design
    value: visit.title
    emptytext: "no title"
    success: (response, newVal) ->
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
  "click #createStudyDesign": (evt) ->
    Meteor.call "createStudyDesign", @_id, (error, studyDesignId) ->
      throwError error if error?

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

  "click .toggleQuestionnaireAtVisit": (evt) ->
    evt.preventDefault()
    questionnaire = @questionnaire
    found = false
    if @visit.questionnaireIds
      _.some @visit.questionnaireIds, (qId)->
        found = qId is questionnaire._id
        found
    doSchedule = !found
    Meteor.call "scheduleQuestionnaireAtVisit", @design._id, @visit._id, @questionnaire._id, doSchedule, (error) ->
      throwError error if error?

  "click .toggleRecordPhysicalDataAtVisit": (evt) ->
    evt.preventDefault()
    Meteor.call "scheduleRecordPhysicalDataAtVisit", @design._id, @visit._id, !@visit.recordPhysicalData, (error) ->
      throwError error if error?

  "click .remove": (evt) ->
    evt.preventDefault()
    if confirm "Are you sure?"
      Meteor.call "removeStudyDesignVisit", @design._id, @visit._id, (error) ->
        throwError error if error?
