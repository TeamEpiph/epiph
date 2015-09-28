onlyIfAdmin = ->
  if Roles.userIsInRole(@userId, ['admin'])
    return true
  else
    @ready()
    return 

onlyIfTherapist = ->
  if Roles.userIsInRole(@userId, ['therapist'])
    return true
  else
    @ready()
    return

onlyIfUser = ->
  if @userId
    return true
  else
    @ready()
    return

#################################################

Meteor.publish "therapists", ->
  return unless onlyIfAdmin.call(@) 
  Meteor.users.find(
    roles: "therapist"
  ,
    fields:
      _id: 1
      username: 1
      emails: 1
      profile: 1
      roles: 1
      status: 1
      createdAt: 1
  )

Meteor.publish "users", ->
  return unless onlyIfAdmin.call(@)
  Meteor.users.find( {},
    fields:
      _id: 1
      username: 1
      emails: 1
      profile: 1
      roles: 1
      status: 1
      createdAt: 1
  )

Meteor.publish "userProfiles", ->
  return unless onlyIfAdmin.call(@)
  Meteor.users.find( {},
    fields:
      _id: 1
      username: 1
      emails: 1
      profile: 1
  )

Meteor.publish "studies", ->
  return unless onlyIfAdmin.call(@) 
  Studies.find()
Meteor.publish "study", (_id) ->
  return unless onlyIfAdmin.call(@) 
  Studies.find(_id: _id)

Meteor.publish "studyDesignsForStudy", (studyId) ->
  return unless onlyIfAdmin.call(@) 
  StudyDesigns.find(studyId: studyId)

Meteor.publish "patients", ->
  if Roles.userIsInRole(@userId, ['admin'])
    return Patients.find()
  else if Roles.userIsInRole(@userId, ['therapist'])
    return Patients.find therapistId: @userId
  else
    @ready()
    return

Meteor.publish "patientsForStudy", (studyID) ->
  return unless onlyIfAdmin.call(@)
  Patients.find
    studyId: studyID


#Meteor.publish "visitsForPatient", (patientId) ->
#	patient = Patients.findOne patientId
#	if patient?
#    if Roles.userIsInRole(@userId, ['admin']) or 
#    (Roles.userIsInRole(@userId, 'therapist') and patient.therapistId is @userId)
#      return Visits.find
#        patientId: patientId
#  @ready()

#Meteor.publish "physioRecordsForVisit", (visitId) ->
#  visit = Visits.findOne visitId
#  if visit?
#    patient = Patients.findOne visit.patientId
#    if patient?
#      if Roles.userIsInRole(@userId, ['admin']) or 
#      (Roles.userIsInRole(@userId, 'therapist') and patient.therapistId is @userId)
#        return PhysioRecords.find
#          'metadata.visitId': visit._id
#  @ready()
#
#Meteor.publish "answersForVisitAndQuestionnaire", (visitId, questionnaireId) ->
#  visit = Visits.findOne visitId
#  if visit?
#    patient = Patients.findOne visit.patientId
#    if patient?
#      if Roles.userIsInRole(@userId, ['admin']) or 
#      (Roles.userIsInRole(@userId, 'therapist') and patient.therapistId is @userId)
#        return Answers.find
#          visitId: visit._id
#          questionnaireId: questionnaireId
#  @ready()

Meteor.publish "studyForPatient", (_id) ->
  if Roles.userIsInRole(@userId, ['admin'])
    patient = Patients.findOne _id: _id
    if patient?
      return Studies.find _id: patient.studyId
  else if Roles.userIsInRole(@userId, ['therapist'])
    patient = Patients.findOne
      _id: _id
      therapistId: @userId
    if patient?
      return Studies.find _id: patient.studyId
  @ready()

Meteor.publish "studyDesignForPatient", (_id) ->
	patient = Patients.findOne _id: _id
	if patient?
    studyDesign = StudyDesigns.find studyId: patient.studyId
    if Roles.userIsInRole(@userId, ['admin']) or 
    (Roles.userIsInRole(@userId, 'therapist') and patient.therapistId is @userId)
      return studyDesign
  @ready()


Meteor.publishComposite 'studyCompositesForPatient', (patientId) ->
  find: ->
    patient = Patients.findOne _id: patientId
    if patient?
      if Roles.userIsInRole(@userId, ['admin']) or 
      (Roles.userIsInRole(@userId, 'therapist') and patient.therapistId is @userId)
        return Patients.find _id: patientId
    return null
  children: [
    find: (patient) ->
      Studies.find _id: patient.studyId
  ,
    find: (patient) ->
      StudyDesigns.find _id: patient.studyDesignId
    children: [
      find: (studyDesign) ->
        #FIXME
        qIds = _.unique studyDesign.questionnaireIds
        Questionnaires.find
          _id: {$in: qIds }
      children: [
        find: (questionnaire) ->
          Questions.find
            questionnaireId: questionnaire._id
      ]
    ]
  ]
        
    
Meteor.publishComposite 'visitsCompositeForPatient', (patientId) ->
  find: ->
    patient = Patients.findOne patientId
    if patient?
      if Roles.userIsInRole(@userId, ['admin']) or 
      (Roles.userIsInRole(@userId, 'therapist') and patient.therapistId is @userId)
        return Patients.find _id: patientId
    return null
  children: [
    find: (patient) ->
      Visits.find
        patientId: patient._id
    children: [
      find: (visit) ->
        Answers.find
          visitId: visit._id
    ,
      find: (visit) ->
        PhysioRecords.find
          'metadata.visitId': visit._id
    ]
  ]

#  find visitIds and questionnaireIds
#  qIds = []
#  vIds = Visits.find
#    patientId: patientId
#  .map (v) ->
#    qIds = qIds.concat(v.questionnaireIds)
#    v._id
#  studyDesign = StudyDesigns.findOne(studyId: patient.studyId)
#  qIds.concat studyDesign.questionnaireIds
#  qIds = _.unique qIds
#return [
#  Visits.find
#    patientId: patientId
#  Questionnaires.find
#    _id: {$in: qIds}
#  Questions.find
#    questionnaireId: {$in: qIds}
#  Answers.find
#    visitId: {$in: vIds}
#  PhysioRecords.find
#    'metadata.visitId': {$in: vIds}
#      ]


#####################################

Meteor.publish "questionnaires", ->
  return unless onlyIfUser.call(@) 
  Questionnaires.find()
Meteor.publish "questions", ->
  return unless onlyIfUser.call(@) 
  Questions.find()
Meteor.publish "questionsForQuestionnaire", (questionnaireId)->
  return unless onlyIfUser.call(@) 
  Questions.find
    questionnaireId: questionnaireId
