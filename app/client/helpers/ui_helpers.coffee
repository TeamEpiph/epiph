Template.registerHelper "printBool", (bool) ->
  return "yes" if bool
  return "no"

Template.registerHelper "isProduction", ->
  process.env.NODE_ENV?

Template.registerHelper "headTitle", (title) ->
  document.title = title
  ""

Template.registerHelper "headDescription", (desc) ->
  document.description = desc
  ""
