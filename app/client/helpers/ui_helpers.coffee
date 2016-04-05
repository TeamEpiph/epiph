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

Template.registerHelper "fileSizeSani", (size) ->
  if size > 1000
    "#{(size/1000).toFixed(1)} kB"
  else if size > 1000000
    "#{(size/1000000).toFixed(1)} MB"
  else if size > 1000000000
    "#{(size/1000000000).toFixed(1)} GB"
  else
    "#{(size)} B"

Template.registerHelper "eq", (a,b) ->
  a is b
Template.registerHelper "neq", (a,b) ->
  a isnt b
Template.registerHelper "eq_or0", (a,b) ->
  a is b or b is 0
Template.registerHelper "or", (a,b) ->
  a isnt 0 or b isnt 0
Template.registerHelper "eq_or", () ->
  a = arguments[0]
  i = 1
  while i < arguments.length
    b = arguments[i]
    return true if a is b
    i++
  return false

Template.registerHelper "percentage", (a, b) ->
  "#{Math.round(100/a*b)}%"
