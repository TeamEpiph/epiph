if Meteor.users.find().count() is 0
  now = new Date().getTime()
  users = [
    {
    name: "Patrick Recher"
    email: "patrick.recher@gmail.com"
    username: "patte"
    password: "mammut"
    roles: ["admin", "therapist", "analyst"]
    }
    {
    name: "Lukas Fürer"
    email: "lukas.fuerer@unibas.ch"
    username: "lüsche"
    password: "asdfasdf"
    roles: ["admin", "therapist", "analyst"]
    }
    {
    name: "Ronan Zimmermann"
    email: "ronan.zimmermann@unibas.ch"
    username: "ronan"
    password: "asdfasdf"
    roles: ["admin", "therapist", "analyst"]
    }
    {
    name: "Doktor Sommer"
    email: "doktor.sommer@patpat.ch"
    username: "drsommer"
    password: "asdfasdf"
    roles: ["therapist"]
    }
  ]
  _.each users, (user) ->
    _id = undefined
    _id = Accounts.createUser(
      email: user.email
      username: user.username
      password: user.password
      profile:
        name: user.name
    )
    # Need _id of existing user record so this call must come 
    # after `Accounts.createUser` or `Accounts.onCreate`
    Roles.addUsersToRoles _id, user.roles  if user.roles.length > 0
    return

  userCursor = Meteor.users.find({})
  userCursor.forEach (user) ->
    console.log('added user:'+user.username)
    return

  return
