onlyIfAdmin = ->
  if !Roles.userIsInRole(@userId, ['admin'])
    @stop()
    return

Meteor.publish "users", ->
  onlyIfAdmin.call(@) 
  Meteor.users.find()

#####################################
onlyIfTherapist = ->
  if !Roles.userIsInRole(@userId, ['therapist'])
    @stop()
    return

Meteor.publish "patients", ->
  onlyIfTherapist.call(@) 
  Patients.find
    therapistId: @userId

