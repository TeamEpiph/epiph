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
      { key: 'emails', label: 'eMail', fn: (v,o) -> o.emails[0].address }
      { key: 'roles', label: 'roles', fn: (v,o) -> if v? then v.sort().join(', ') else "" }
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
      throwError error if error

  "click .removeFromRole": (evt)->
    evt.stopImmediatePropagation()
    id = $(evt.target).closest("button").data().id
    role = $(evt.target).closest("button").data().role
    swal {
      title: 'Are you sure?'
      text: 'Do you want to remove the user from the role?'
      type: 'warning'
      showCancelButton: true
      confirmButtonText: 'Yes'
    }, ->
      Meteor.call "removeUserFromRoles", id, role, (error) ->
        throwError error if error

Template.usersTableButtons.helpers
  isInRole: (_id, role) ->
    Roles.userIsInRole(_id, role)
