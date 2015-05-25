Meteor.methods
  addUserToRoles: (user_id, roles) ->
    check(user_id, String)
    checkIfAdmin()
    Roles.addUsersToRoles(user_id, roles)

  removeUserFromRoles: (user_id, roles) ->
    check(user_id, String)
    checkIfAdmin()
    Roles.removeUsersFromRoles(user_id, roles)
