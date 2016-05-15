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
      { key: 'emails', label: 'mongoDB username', fn: (v,o) -> if Roles.userIsInRole(o, "mongoRead") then __getMongodbUsername(o) else "" }
      { key: 'roles', label: 'roles', fn: (v,o) -> if v? then v.sort().join(', ') else "" }
      { key: 'status', label: 'online', tmpl: Template.userStatusTableCell }
      { key: 'buttons', label: '', tmpl: Template.usersTableButtons }
    ]


Template.usersTableButtons.helpers
  systemRoles: ->
    __systemRoles

Template.usersTableButtons.events
  "click .addToRole": (evt)->
    id = $(evt.target).closest("button").data().id
    role = $(evt.target).closest("button").data().role
    if role is "mongoRead"
      swal {
        title: 'Password'
        text: """Please provide a password for mongoDB access. Because you might type it into script files, it has to be different from your user password."""
        type: 'input'
        showCancelButton: true
        confirmButtonText: 'Yes'
        inputPlaceholder: "Please provide a password, (min: 8 characters)."
        closeOnConfirm: false
      }, (confirmedWithPassword)->
        if confirmedWithPassword is false #cancel
          swal.close()
        else
          if !confirmedWithPassword? or confirmedWithPassword.length is 0 or confirmedWithPassword.length < 8
            swal.showInputError "Please provide a password, (min: 8 characters)."
          else
            Meteor.call "addUserToRole", id, role, confirmedWithPassword, (error) ->
              if error?
                throwError error
              else
                swal.close()
        return
    else
      Meteor.call "addUserToRole", id, role, (error) ->
        throwError error if error?
    return

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
      Meteor.call "removeUserFromRole", id, role, (error) ->
        throwError error if error

Template.usersTableButtons.helpers
  isInRole: (_id, role) ->
    Roles.userIsInRole(_id, role)
