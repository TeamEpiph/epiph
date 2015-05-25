Template.users.helpers
  users: ->
    Meteor.users.find( )

  usersReactiveTableSettings: ->
    useFontAwesome: true,
    rowsPerPage: 15,
    showFilter: true,
    fields: [
      { key: 'profile.name', label: 'name' }
      'username',
      { key: 'roles', label: 'roles', fn: (v,o) -> v.sort().join(', ') }
      { key: 'status', label: 'online', tmpl: Template.userStatusTableCell }
      { key: 'buttons', label: '', tmpl: Template.usersTableButtons }
    ]


Template.usersTableButtons.helpers
  systemRoles: ->
    [
      role: "admin"
      icon: "fa-child"
    ,
      role: "therapist"
      icon: "fa-user-md"
    ,
      role: "analyst"
      icon: "fa-graduation-cap"
    ]

Template.usersTableButtons.events
  "click .addToRole": (evt)->
    id = $(evt.target).closest("button").data().id
    role = $(evt.target).closest("button").data().role
    Meteor.call "addUserToRoles", id, role, (error) ->
      throwError error.reason if error

  "click .removeFromRole": (evt)->
    evt.stopImmediatePropagation()
    id = $(evt.target).closest("button").data().id
    role = $(evt.target).closest("button").data().role
    if confirm("Really?")
      Meteor.call "removeUserFromRoles", id, role, (error) ->
        throwError error.reason if error

Template.usersTableButtons.helpers
  isInRole: (_id, role) ->
    Roles.userIsInRole(_id, role)
