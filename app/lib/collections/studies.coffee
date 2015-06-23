class @Study
  constructor: (doc) ->
    _.extend this, doc

  creator: ->
    Meteor.users.findOne _id: @creatorId

  editingNotAllowed: ->
    Meteor.userId() isnt @creatorId

@Studies = new Meteor.Collection("studies",
  transform: (doc) ->
    new Study(doc)
)

Studies.before.insert BeforeInsertTimestampHook
Studies.before.update BeforeUpdateTimestampHook

#FIXME
Studies.allow
  insert: (userId, doc) ->
    false
  update: (userId, doc, fieldNames, modifier) ->
    true
  remove: (userId, doc) ->
    false

Meteor.methods
  "createStudy": (title) ->
    _id = Studies.insert
      title: "new Study"
      creatorId: Meteor.userId()
    _id

  "removeStudy": (_id) ->
    #TODO: check if allowed
    Studies.remove
      _id: _id
