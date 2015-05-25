Template.header.helpers
  activeRouteClass: (routeNames...)->
    args = Array::slice.call(routeNames, 0)
    args.pop()
    active = _.any(args, (name) ->
      Router.current() and Router.current().route.getName() is name
    )
    return "active" if active
    ""
