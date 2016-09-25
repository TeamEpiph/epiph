onlyIfAdmin = ->
  if Roles.userIsInRole(@userId, ['admin'])
    return true
  else
    @ready()
    return 

onlyIfAdminOrCaseManager = ->
  if Roles.userIsInRole(@userId, ['admin', 'caseManager'])
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

Meteor.publish "caseManagers", ->
  return unless onlyIfAdmin.call(@) 
  Meteor.users.find(
    roles: "caseManager"
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
  return unless onlyIfAdminOrCaseManager.call(@) 
  Studies.find()
Meteor.publish "study", (_id) ->
  return unless onlyIfAdminOrCaseManager.call(@) 
  Studies.find(_id: _id)

Meteor.publish "studyDesigns", ->
  return unless onlyIfAdminOrCaseManager.call(@) 
  StudyDesigns.find()
Meteor.publish "studyDesignsForStudy", (studyIds) ->
  return unless onlyIfAdminOrCaseManager.call(@) 
  if typeof studyIds is 'string'
    studyIds = [studyIds]
  StudyDesigns.find
    studyId: {$in: studyIds}

Meteor.publish "patients", ->
  if Roles.userIsInRole(@userId, ['admin'])
    return Patients.find()
  else if Roles.userIsInRole(@userId, ['caseManager'])
    return Patients.find caseManagerId: @userId
  else
    @ready()
    return

Meteor.publish "patientsForStudy", (studyID) ->
  return unless onlyIfAdmin.call(@)
  Patients.find
    studyId: studyID


Meteor.publish "studyForPatient", (_id) ->
  if Roles.userIsInRole(@userId, ['admin'])
    patient = Patients.findOne _id: _id
    if patient?
      return Studies.find _id: patient.studyId
  else if Roles.userIsInRole(@userId, ['caseManager'])
    patient = Patients.findOne
      _id: _id
      caseManagerId: @userId
    if patient?
      return Studies.find _id: patient.studyId
  @ready()

Meteor.publish "studyDesignForPatient", (_id) ->
	patient = Patients.findOne _id: _id
	if patient?
    studyDesign = StudyDesigns.find studyId: patient.studyId
    if Roles.userIsInRole(@userId, ['admin']) or 
    (Roles.userIsInRole(@userId, 'caseManager') and patient.caseManagerId is @userId)
      return studyDesign
  @ready()


Meteor.publishComposite 'studyCompositesForPatient', (patientId) ->
  find: ->
    patient = Patients.findOne _id: patientId
    if patient?
      if Roles.userIsInRole(@userId, ['admin']) or 
      (Roles.userIsInRole(@userId, 'caseManager') and patient.caseManagerId is @userId)
        return Patients.find _id: patientId
    return null
  children: [
    find: (patient) ->
      Studies.find _id: patient.studyId
  ,
    find: (patient) ->
      StudyDesigns.find _id: $in: patient.studyDesignIds
    children: [
      find: (studyDesign) ->
        if studyDesign.questionnaireIds? and studyDesign.questionnaireIds.length > 0
          Questionnaires.find
            _id: {$in: studyDesign.questionnaireIds }
        else
          null
      children: [
        find: (questionnaire) ->
          Questions.find
            questionnaireId: questionnaire._id
      ]
    ]
  ]
        
    
Meteor.publish "visits", ->
  return unless onlyIfAdmin.call(@) 
  Visits.find()

Meteor.publishComposite 'visitsCompositeForPatient', (patientId) ->
  find: ->
    patient = Patients.findOne patientId
    if patient?
      if Roles.userIsInRole(@userId, ['admin']) or 
      (Roles.userIsInRole(@userId, 'caseManager') and patient.caseManagerId is @userId)
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
    ]
  ]


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

#####################################

Meteor.publish "activities", ->
  return unless onlyIfAdmin.call(@) 
  Activities.find()

#####################################

Meteor.publish "exportTables", ->
  return unless onlyIfAdmin.call(@) 
  ExportTables.find()
