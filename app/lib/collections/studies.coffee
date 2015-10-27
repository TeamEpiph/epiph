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

Studies.allow
  update: (userId, doc, fieldNames, modifier) ->
    #TODO check if allowed
    notAllowedFields = _.without fieldNames, 'title', 'updatedAt'
    return false if notAllowedFields.length > 0
    true

Meteor.methods
  "createStudy": (title) ->
    #TODO: check if allowed
    _id = Studies.insert
      title: "new Study"
      creatorId: Meteor.userId()
    _id

  "removeStudy": (_id) ->
    #TODO: check if allowed
    Studies.remove
      _id: _id
