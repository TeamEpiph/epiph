@checkIfAdmin = ->
  user = Meteor.user()
  throw new Meteor.Error(401, "You need to login") unless user
  throw new Meteor.Error(401, "You need to be admin") unless Roles.userIsInRole(user, 'admin')

@canAddPatient = (studyId) ->
  user = Meteor.user()
  throw new Meteor.Error(401, "You need to login") unless user
  authorized = false
  if Roles.userIsInRole(user, 'admin')
    authorized = true
  else
    patients = Patients.find(
      {'studyId': studyId, 'caseManagerIds': user._id}
    ).map((x) -> x)
    authorized = patients? and patients.length > 0
  if !authorized
    throw new Meteor.Error(401, 'Unauthorized')

@canUpdatePatient = (patientId) ->
  user = Meteor.user()
  throw new Meteor.Error(401, "You need to login") unless user
  authorized = false
  if Roles.userIsInRole(user, 'admin')
    authorized = true
  else
    patients = Patients.find(
      {'_id': patientId, 'caseManagerIds': user._id}
    ).map((x) -> x)
    authorized = patients? and patients.length > 0
  if !authorized
    throw new Meteor.Error(401, 'Unauthorized')
