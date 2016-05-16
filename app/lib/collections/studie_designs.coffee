@StudyDesigns = new Meteor.Collection("study_designs")

StudyDesigns.before.insert BeforeInsertTimestampHook
StudyDesigns.before.update BeforeUpdateTimestampHook

schema =
  'title':
    type: String
  'studyId':
    type: String
  'creatorId':
    type: String
  'visits':
    type: [Object]
    optional: true
  'visits.$._id':
    type: String
  'visits.$.title':
    type: String
  'visits.$.index':
    type: Number
  'visits.$.daysOffsetFromPrevious':
    type: Number
    optional: true
  'visits.$.daysOffsetFromBaseline':
    type: Number
    optional: true
  'visits.$.questionnaireIds':
    type: [String]
    optional: true
  'visits.$.recordPhysicalData':
    type: Boolean
    optional: true
  'questionnaireIds':
    type: [String]
    optional: true
  'recordPhysicalData':
    type: Boolean
    optional: true
  'updatedAt':
    type: Number
    optional: true
  'createdAt':
    type: Number
    optional: true
StudyDesigns.attachSchema new SimpleSchema(schema)

Meteor.methods
  "createStudyDesign": (studyId) ->
    checkIfAdmin()

    study = Studies.findOne studyId
    throw new Meteor.Error(403, "study not found.") unless study?
    throw new Meteor.Error(400, "Study is locked. Please unlock it first.") if study.isLocked

    count = StudyDesigns.find(
      studyId: studyId
    ).count()
    _id = StudyDesigns.insert
      title: "design #{count+1}"
      studyId: studyId
      creatorId: Meteor.userId()
      visits: [
        _id: new Meteor.Collection.ObjectID()._str
        day: 0
        index: 0
        title: "visit 1"
      ]
    _id

  "updateStudyDesignTitle": (studyDesignId, title) ->
    checkIfAdmin()
    check title, String

    checkStudyDesignAndStudy(studyDesignId)

    studyDesign = StudyDesigns.findOne studyDesignId
    throw new Meteor.Error(403, "studyDesign not found.") unless studyDesign?
    StudyDesigns.update studyDesignId,
      $set: title: title
    return

  "copyStudyDesign": (studyDesignId) ->
    checkIfAdmin()
    check studyDesignId, String

    checkStudyDesignAndStudy(studyDesignId)
    design = StudyDesigns.findOne studyDesignId

    delete design._id
    design.title += " copy"
    design.creatorId = Meteor.userId()

    design.visits.forEach (v) ->
      v._id = new Mongo.ObjectID()._str

    StudyDesigns.insert design

  "removeStudyDesign": (studyDesignId) ->
    checkIfAdmin()
    check studyDesignId, String

    checkStudyDesignAndStudy(studyDesignId)

    #check patients
    design = StudyDesigns.findOne studyDesignId
    patientIds = Patients.find
      studyDesignId: design._id
    .map (patient) ->
      patient.id
    if patientIds.length > 0
      throw new Meteor.Error(500, "Can't remove study design because these patients are mapped to it: #{patientIds.join(", ")}")

    error = null
    _.some design.visits, (visit) ->
      next = true
      try
        Meteor.call "removeStudyDesignVisit", design._id, visit._id
      catch e
        error = e
        next = false
      next

    if error?
      throw error

    StudyDesigns.remove design._id
    return

  "addStudyDesignVisit": (studyDesignId) ->
    checkIfAdmin()
    check studyDesignId, String

    checkStudyDesignAndStudy(studyDesignId)

    design = StudyDesigns.findOne studyDesignId
    index = design.visits.length
    title = "visit #{index+1}"
    visit =
      _id: new Meteor.Collection.ObjectID()._str
      title: title
      index: index

    StudyDesigns.update studyDesignId,
      $push: visits: visit

  "changeStudyDesignVisitTitle": (studyDesignId, visitId, title) ->
    checkIfAdmin()
    check studyDesignId, String
    check visitId, String
    check title, String

    checkStudyDesignAndStudy(studyDesignId)

    n = StudyDesigns.update
      _id: studyDesignId
      'visits._id': visitId
    ,
      $set: 'visits.$.title': title
    throw new Meteor.Error(500, "changeStudyVisitTitle: no StudyDesign.visit to update found") unless n > 0

    #update existing visits
    Visits.update
      designVisitId: visitId
    ,
      $set: title: title
    ,
      multi: true
    return

  "changeStudyDesignVisitDaysOffset": (studyDesignId, visitId, daysOffset, from) ->
    checkIfAdmin()
    check studyDesignId, String
    check visitId, String
    check from, String
    if from isnt "previous" and from isnt "baseline"
      throw new Meteor.Error(500, "from must be 'previous' or 'baseline'") 

    daysOffset = null if isNaN(daysOffset)
    if daysOffset? #allow null
      daysOffset = parseInt(daysOffset)
      check daysOffset, Number

    checkStudyDesignAndStudy(studyDesignId)

    design = StudyDesigns.findOne studyDesignId
    visit = _.find design.visits, (v) ->
      v._id is visitId
    throw new Meteor.Error(500, "studyDesign.visit not found") unless visit?

    if daysOffset? and ( (from is "previous" and visit.daysOffsetFromBaseline?) or (from is "baseline" and visit.daysOffsetFromPrevious?))
        throw new Meteor.Error("a visit can either have an offset from previous or baseline")

    if from is "previous"
      n = StudyDesigns.update { _id: studyDesignId, 'visits._id': visitId},
        $set: 'visits.$.daysOffsetFromPrevious': daysOffset
    else
      n = StudyDesigns.update { _id: studyDesignId, 'visits._id': visitId},
        $set: 'visits.$.daysOffsetFromBaseline': daysOffset
    throw new Meteor.Error(500, "no StudyDesign.visit to update found") unless n > 0

    #update existing visits
    if from is "previous"
      if daysOffset?
        Visits.update { designVisitId: visitId },
          $set: daysOffsetFromPrevious: daysOffset
        ,
          multi: true
      else
        Visits.update { designVisitId: visitId },
          $unset: daysOffsetFromPrevious: 1
        ,
          multi: true
    else
      if daysOffset?
        Visits.update { designVisitId: visitId },
          $set: daysOffsetFromBaseline: daysOffset
        ,
          multi: true
      else
        Visits.update { designVisitId: visitId },
          $unset: daysOffsetFromBaseline: 1
        ,
          multi: true

    return

  "scheduleQuestionnairesAtVisit": (studyDesignId, visitId, questionnaireIds) ->
    checkIfAdmin()
    check studyDesignId, String
    check visitId, String
    check questionnaireIds, [String]

    checkStudyDesignAndStudy(studyDesignId)

    n = StudyDesigns.update
      _id: studyDesignId
      'visits._id': visitId
    ,
      $set: 'visits.$.questionnaireIds': questionnaireIds
    throw new Meteor.Error(500, "scheduleQuestionnaireAtVisit: no StudyDesign with that visit found") unless n > 0

    #update existing visits
    Visits.find
      designVisitId: visitId
    .forEach (visit) ->
      removedQuestionnaireIds = _.difference visit.questionnaireIds, questionnaireIds
      usedQuestionnaireIds = removedQuestionnaireIds.filter (rQuestId) ->
        rQuestionIds = Questions.find(
          questionnaireId: rQuestId
        ).map( (q) -> q._id )
        c = Answers.find(
          visitId: visit._id
          questionId: {$in: rQuestionIds}
        ).count()
        if c > 0
          return true
        return false

      questionnaireIdsForVisit = _.clone questionnaireIds
      usedQuestionnaireIds.forEach (qId) ->
        questionnaireIdsForVisit.push qId

      Visits.update visit._id,
        $set: questionnaireIds: questionnaireIdsForVisit

    updateQuestionnaireIdsOfStudyDesign(studyDesignId)
    return


  "scheduleRecordPhysicalDataAtVisit": (studyDesignId, visitId, doSchedule) ->
    checkIfAdmin()
    check visitId, String
    check studyDesignId, String

    checkStudyDesignAndStudy(studyDesignId)

    n = StudyDesigns.update
      _id: studyDesignId
      'visits._id': visitId
    ,
      $set: 'visits.$.recordPhysicalData': doSchedule
    throw new Meteor.Error(500, "scheduleRecordPhysicalDataAtVisit: no StudyDesign with that visit found") unless n > 0

    updateRecordPhysicalDataOfStudyDesign(studyDesignId)

    #update existing visits
    Visits.find
      designVisitId: visitId
    .forEach (visit) ->
      if doSchedule
        Visits.update visit._id,
          $set: recordPhysicalData: true
      else
        Visits.update visit._id,
          $set: recordPhysicalData: false
    return


  "moveStudyDesignVisit": (studyDesignId, visitId, up) ->
    checkIfAdmin()
    check visitId, String
    check studyDesignId, String

    checkStudyDesignAndStudy(studyDesignId)

    design = StudyDesigns.findOne studyDesignId
    visit = _.find design.visits, (v) ->
      v._id is visitId
    throw new Meteor.Error(500, "removeStudyDesignVisit: visit not found") unless visit?

    move = -1
    move = 1 if !up
    return if visit.index is 0 and move is -1
    return if visit.index+1 >= design.visits.length and move is 1
    StudyDesigns.update
      _id: studyDesignId
      'visits.index': visit.index+move
    ,
      $inc: 'visits.$.index': -move
    StudyDesigns.update
      _id: studyDesignId
      'visits._id': visitId
    ,
      $inc: 'visits.$.index': move

    #update existing visits
    designVisitIds = design.visits.map (designVisit) ->
      designVisit._id
    Visits.update
      designVisitId: { $in: designVisitIds }
      index: visit.index+move
    ,
      $inc: index: -move
    ,
      multi: true
    Visits.update
      designVisitId: visitId
    ,
      $inc: index: move
    ,
      multi: true
    return

  "removeStudyDesignVisit": (studyDesignId, visitId) ->
    checkIfAdmin()
    check visitId, String
    check studyDesignId, String

    checkStudyDesignAndStudy(studyDesignId)

    design = StudyDesigns.findOne studyDesignId
    visit = _.find design.visits, (v) ->
      v._id is visitId
    throw new Meteor.Error(500, "removeStudyDesignVisit: visit not found") unless visit?

    #check existing visits
    visits = Visits.find
      designVisitId: visitId
    .fetch()
    foundData = _.some visits, (visit) ->
      questionIds = Questions.find
        questionnaireId:
          $in: visit.questionnaireIds
      .map( (q) -> q._id )
      c1 = Answers.find
        visitId: visit._id
        questionId: {$in: questionIds}
      .count()
      if c1 > 0
        console.log "the following visit of the template has data attached:"
        console.log visit
        return true
      return false
    throw new Meteor.Error(500, "The visit is used by at least one patient, has data attached to it and can therefore not be deleted. Please consider using a copy of this design and assign it to new patients.") if foundData
 
    #remove existing visits
    Visits.remove
      designVisitId: visitId

    StudyDesigns.update studyDesignId,
      $pull: {visits: {_id: visitId}}

    #TODO normalize visits into it's own collection
    #to avoid stuff like this
    index = visit.index+1
    loop
      n = StudyDesigns.update
        _id: studyDesignId
        'visits.index': index
      ,
        $inc: {'visits.$.index': -1}
      index += 1
      break if n is 0

    updateQuestionnaireIdsOfStudyDesign(studyDesignId)
    updateRecordPhysicalDataOfStudyDesign(studyDesignId)
    return

checkStudyDesignAndStudy = (studyDesignId) ->
  design = StudyDesigns.findOne studyDesignId
  throw new Meteor.Error(500, "StudyDesign #{studyDesignId} not found!") unless design?
  study = Studies.findOne design.studyId
  throw new Meteor.Error(400, "study (#{design.studyDesignId}) not found") unless study?
  throw new Meteor.Error(400, "Study is locked. Please unlock it first.") if study.isLocked
  return


updateQuestionnaireIdsOfStudyDesign = (studyDesignId) ->
  design = StudyDesigns.findOne studyDesignId
  throw new Meteor.Error(500, "updateQuestionnaireIdsOfStudyDesign: studyDesign not found") unless design?
  questionnaireIds = []
  design.visits.forEach (visit) ->
    if visit.questionnaireIds? and visit.questionnaireIds.length > 0
      questionnaireIds = _.union questionnaireIds, visit.questionnaireIds
    #questionnaireIds from design.visits and real visits may differt in case a questionnaire, for which
    #data was collected already, got removed from the design.visit
    #here we search for other questionnaireIds
    Visits.find(
      designVisitId: visit._id
    ).forEach (v) ->
      questionnaireIds = _.union questionnaireIds, v.questionnaireIds
  StudyDesigns.update studyDesignId,
    $set: questionnaireIds: questionnaireIds
  return

updateRecordPhysicalDataOfStudyDesign = (studyDesignId) ->
  design = StudyDesigns.findOne studyDesignId
  throw new Meteor.Error(500, "updateRecordPhysicalDataOfStudyDesign: studyDesign not found") unless design?
  recordPhysicalData = false
  _.some design.visits, (visit) ->
    if visit.recordPhysicalData?
      recordPhysicalData = visit.recordPhysicalData
    recordPhysicalData
  StudyDesigns.update studyDesignId,
    $set: recordPhysicalData: recordPhysicalData
  return
