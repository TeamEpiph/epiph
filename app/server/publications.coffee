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

Meteor.publish "studyDesigns", ->
  return unless onlyIfAdmin.call(@) 
  StudyDesigns.find()
Meteor.publish "studyDesignsForStudy", (studyIds) ->
  return unless onlyIfAdmin.call(@) 
  if typeof studyIds is 'string'
    studyIds = [studyIds]
  StudyDesigns.find
    studyId: {$in: studyIds}

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
        
    
Meteor.publish "visits", ->
  return unless onlyIfAdmin.call(@) 
  Visits.find()

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
