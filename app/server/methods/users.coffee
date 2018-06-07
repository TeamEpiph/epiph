Future = Npm.require('fibers/future')
Meteor.methods
  addUserToRole: (userId, role, password) ->
    check(userId, String)
    checkIfAdmin()

    user = Meteor.users.findOne userId
    throw new Meteor.Error(403, "user not found.") unless user?

    #check role
    found = false
    _.some __systemRoles, (r) ->
      if r.role is role
        found = true
      found
    throw new Meteor.Error(400, "role #{role} doesn't exist.") if !found

    if role.indexOf('mongoRead') > -1
      check(password, String)
      if password.length < 8
        throw new Meteor.Error(400, "password doesn't meet requirements.")

      result = Accounts._checkPassword(user, password)
      if !result.error?
        throw new Meteor.Error(400, "the password must not be the same as the users password.")

      username = __getMongodbUsername user
      db = Meteor.users.rawDatabase()
      #https://mongodb.github.io/node-mongodb-native/api-generated/admin.html#adduser
      future = new Future
      db.addUser username, password,
        roles: [ { role: "read", db: "epiph"} ]
      , (error, result) ->
        if error?
          future.throw new Meteor.Error(500, error.errmsg)
        else
          future.return result
      future.wait()
    Roles.addUsersToRoles(userId, role)

  removeUserFromRole: (userId, role) ->
    check(userId, String)
    checkIfAdmin()
    user = Meteor.users.findOne userId
    throw new Meteor.Error(403, "user not found.") unless user?

    if role.indexOf('mongoRead') > -1
      #https://mongodb.github.io/node-mongodb-native/api-generated/admin.html#removeuser
      db = Meteor.users.rawDatabase()
      username = __getMongodbUsername user
      future = new Future
      db.removeUser username, (error, result) ->
        if error?
          future.throw new Meteor.Error(500, error.errmsg)
        else
          future.return result
      future.wait()
    Roles.removeUsersFromRoles(userId, role)

  removeUser: (userId) ->
    checkIfAdmin()
    # Logout user
    Meteor.users.update(userId, {$set : { "services.resume.loginTokens" : [] }}, {multi:true})
    # Delete user
    Meteor.users.remove(userId)
