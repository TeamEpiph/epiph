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

Meteor.methods
  "createStudy": (title) ->
    #TODO: check if allowed
    _id = Studies.insert
      title: "new Study"
      key: "new key"
      creatorId: Meteor.userId()
    _id

  "changeStudyTitle": (_id, title) ->
    check(_id, String)
    check(title, String)
    #TODO: check if allowed
    Studies.update _id,
      $set: {title: title}

  "removeStudy": (_id) ->
    #TODO: check if allowed
    Studies.remove
      _id: _id
