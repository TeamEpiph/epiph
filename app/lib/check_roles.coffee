@checkIfAdmin = ->
  user = Meteor.user()
  throw new Meteor.Error(401, "You need to login") unless user
  throw new Meteor.Error(401, "You need to be admin") unless Roles.userIsInRole(user, 'admin')

@checkIfTherapist = ->
  user = Meteor.user()
  throw new Meteor.Error(401, "You need to login") unless user
  throw new Meteor.Error(401, "You need to be a therapist") unless Roles.userIsInRole(user, 'therapist')
