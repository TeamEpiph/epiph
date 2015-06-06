onlyIfAdmin = ->
  if !Roles.userIsInRole(@userId, ['admin'])
    @ready()
    return

Meteor.publish "users", ->
  onlyIfAdmin.call(@) 
  Meteor.users.find()

#####################################
onlyIfTherapist = ->
  if !Roles.userIsInRole(@userId, ['therapist'])
    @ready()
    return

Meteor.publish "patients", ->
  onlyIfTherapist.call(@) 
  Patients.find
    therapistId: @userId

#####################################
onlyIfUser = ->
  if !@userId
    @ready()
    return

Meteor.publish "questionnaires", ->
  onlyIfUser.call(@) 
  Questionnaires.find()
Meteor.publish "questions", (questionnaireId)->
  onlyIfUser.call(@) 
  Questions.find
    questionnaireId: questionnaireId
