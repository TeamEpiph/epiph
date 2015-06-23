onlyIfAdmin = ->
  if Roles.userIsInRole(@userId, ['admin'])
    return true
  else
    @ready()
    return 


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


#####################################
onlyIfTherapist = ->
  if Roles.userIsInRole(@userId, ['therapist'])
    return true
  else
    @ready()
    return

#####################################
onlyIfUser = ->
  if @userId
    return true
  else
    @ready()
    return

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
