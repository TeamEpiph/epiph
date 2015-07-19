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
    StudyDesigns.find studyId: @_id

  #this: design
  visits: ->
    @visits.sort (a, b)->
      a.index - b.index
    prevDay = 0
    @visits.map (v)->
      daysBetween = v.day-prevDay
      _.extend v,
        date: moment().add(v.day, 'days').toDate()
        daysBetween: daysBetween
      prevDay = v.day
      if daysBetween is 0
        delete v.daysBetween
      v
  
  remainingQuestionnaires: ->
    qIds = @questionnaireIds or []
    qIds = _.union(qIds, (Session.get('editStudyDesignsQuestionnaireIds') or []) )
    Questionnaires.find
      _id: {$nin: qIds}
  questionnaires: ->
    qIds = @questionnaireIds or []
    qIds = _.union(qIds, (Session.get('editStudyDesignsQuestionnaireIds') or []) )
    Questionnaires.find
      _id: {$in: qIds}
      
#this: { studyDesign:StudyDesign visit:StudyDesign.visit questionnaire:Questionnaire }
Template.visitTd.helpers
  iconClass: ->
    self = @
    design = StudyDesigns.findOne
      _id: @studyDesign._id
      #'visits.$._id': @visit._id
      #visits: { $elemMatch: {_id: visitId} }
    #TODO use mongo aggregate
    visitId = @visit._id
    visit = _.find design.visits, (v)->
      v._id is visitId
    #
    found = false
    if visit and visit.questionnaireIds
      _.some visit.questionnaireIds, (qId)->
        found = qId is self.questionnaire._id
        found
    if found
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
    
  "click .mapQuestionnaireToVisit": (evt) ->
    evt.preventDefault()
    Meteor.call "mapQuestionnaireToVisit", @studyDesign._id, @visit._id, @questionnaire._id, (error) ->
      throwError error if error?
