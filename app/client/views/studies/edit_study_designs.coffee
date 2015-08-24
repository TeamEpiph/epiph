AutoForm.hooks
  generateVisitsForm:
    onSubmit: (insertDoc, updateDoc, currentDoc) ->
      Meteor.call "addMultipleStudyDesignVisits", insertDoc, (error) ->
        throwError error if error?
      @done()
      false

Template.editStudyDesigns.helpers
  titleEO: ->
    self = @
    value: @title
    emptytext: "no title"
    success: (response, newVal) ->
      StudyDesigns.update self._id,
        $set: {title: newVal}
      return
  keyEO: ->
    self = @
    value: @key
    emptytext: "no key"
    success: (response, newVal) ->
      StudyDesigns.update self._id,
        $set: {key: newVal}
      return

  designs: ->
    StudyDesigns.find studyId: @_id,
      sort: {createdAt: 1}

  #this: design
  visits: ->
    @visits.sort (a, b)->
      a.day - b.day
    prevDay = 0
    #augment visits
    #http://stackoverflow.com/questions/13789622/accessing-parent-context-in-meteor-templates-and-template-helpers
    self = @
    @visits.map (v)->
      daysBetween = v.day-prevDay
      _.extend v,
        date: moment().add(v.day, 'days').toDate()
        daysBetween: daysBetween
      prevDay = v.day
      if daysBetween is 0
        delete v.daysBetween
      #questionnaireIds
      v.designQuestionnaireIds = self.questionnaireIds
      v
  
  #this design
  hasRemainingQuestionnaires: ->
    qIds = @questionnaireIds or []
    qIds = _.union(qIds, (Session.get('editStudyDesignsQuestionnaireIds') or []) )
    Questionnaires.find(
      _id: {$nin: qIds}
    ).count()

  remainingQuestionnaires: ->
    qIds = @questionnaireIds or []
    qIds = _.union(qIds, (Session.get('editStudyDesignsQuestionnaireIds') or []) )
    Questionnaires.find
      _id: {$nin: qIds}

  #this design 
  questionnaires: ->
    qIds = @questionnaireIds or []
    qIds = _.union(qIds, (Session.get('editStudyDesignsQuestionnaireIds') or []) )
    Questionnaires.find
      _id: {$in: qIds}

  #this visit
  designQuestionnaires: ->
    qIds = @designQuestionnaireIds or []
    qIds = _.union(qIds, (Session.get('editStudyDesignsQuestionnaireIds') or []) )
    Questionnaires.find
      _id: {$in: qIds}

  generateVisitsSchema: ->
    schema =
      studyDesignId:
        type: String
        defaultValue: @_id
        autoform:
          type: "hidden"
          label: false
      title:
        label: "Title"
        type: String
        optional: false
      key:
        label: "Key"
        type: String
        optional: false
      startDay:
        label: "start at day"
        type: Number
        optional: false
        defaultValue: 1
        min: 1
      numVisits:
        label: "number of visits"
        type: Number
        optional: false
        defaultValue: 1
        min: 1
        max: 120
      daysBetween:
        label: "days between visits"
        type: Number
        optional: false
        defaultValue: 1
        min: 1
    new SimpleSchema(schema)

      
#this: { studyDesign:StudyDesign visit:StudyDesign.visit questionnaire:Questionnaire }
Template.editVisitQuestionnaireTd.helpers
  iconClass: ->
    self = @
    found = false
    if @visit.questionnaireIds
      _.some @visit.questionnaireIds, (qId)->
        found = qId is self.questionnaire._id
        found
    if found
      return "fa-check-square-o brand-primary"
    else
      return "fa-square-o hoverOpaqueExtreme"

#this: { studyDesign:StudyDesign visit:StudyDesign.visit }
Template.editVisitPhysTd.helpers
  iconClass: ->
    if @visit.recordPhysicalData?
      return "fa-check-square-o brand-primary"
    else
      return "fa-square-o hoverOpaqueExtreme"
      

Template.editStudyDesigns.events
  "click #createStudyDesign": (evt) ->
    Meteor.call "createStudyDesign", @_id, (error, studyDesignId) ->
      throwError error if error?
    
  "submit #addVisit": (evt) ->
    evt.preventDefault()
    offset = evt.target.offset.value
    if offset? and offset.length > 0
      console.log "offset #{offset}"
    evt.target.offset.value = ""
    evt.target.offset.blur()
    Meteor.call "addStudyDesignVisit", @_id, offset, (error) ->
      throwError error if error?

  "click .addQuestionnaire": (evt) ->
    evt.preventDefault()
    questionnaireId = $(evt.target).data("id")
    qIds = Session.get("editStudyDesignsQuestionnaireIds") or []
    qIds.push questionnaireId
    Session.set "editStudyDesignsQuestionnaireIds", qIds
    
  "click .toggleQuestionnaireAtVisit": (evt) ->
    evt.preventDefault()
    self = @
    found = false
    if @visit.questionnaireIds
      _.some @visit.questionnaireIds, (qId)->
        found = qId is self.questionnaire._id
        found
    doSchedule = !found
    doAllOfGroup = false
    #if @visit.groupId
    #  #TODO description
    #  doAllOfGroup = confirm('Do you want to apply this to all visits of the same group?')
    Meteor.call "scheduleQuestionnaireAtVisit", @studyDesign._id, @visit._id, @questionnaire._id, doSchedule, doAllOfGroup, (error) ->
      throwError error if error?

  "click .toggleRecordPhysicalDataAtVisit": (evt) ->
    evt.preventDefault()
    Meteor.call "scheduleRecordPhysicalDataAtVisit", @studyDesign._id, @visit._id, !@visit.recordPhysicalData, (error) ->
      throwError error if error?
