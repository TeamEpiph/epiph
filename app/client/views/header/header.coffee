Template.header.helpers
  activeRouteClass: (routeNames...)->
    args = Array::slice.call(routeNames, 0)
    args.pop()
    active = _.any(args, (name) ->
      Router.current() and Router.current().route.getName() is name
    )
    return "active" if active
    ""

Template.header.events
  #this is needed to trigger hashchange
  "click #patientsA": (evt) ->
    window.location.hash = ""
    true

  "click #logoutUser": (evt) ->
    AccountsTemplates.logout()
