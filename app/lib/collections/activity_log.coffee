@Activities = new Meteor.Collection("activities")

Activities.before.insert BeforeInsertTimestampHook
Activities.before.update = ->
  throw new Meteor.Error(400, "removing or updating Activities is not allowed.")
Activities.before.remove = -> 
  throw new Meteor.Error(400, "removing or updating Activities is not allowed.")

Meteor.methods
  "logActivity": (description, level, reason, payload) ->
    check description, String
    check level, String
    userId = Meteor.userId()
    throw new Meteor.Error(401, "You need to login") unless userId?
    console.log "logActivity: #{description}, #{level}, #{userId}, #{payload}"
    Activities.insert
      description: description
      level: level
      userId: userId
      reason: reason if reason?
      payload: payload if payload?
    return

