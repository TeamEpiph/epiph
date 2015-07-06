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

Template.registerHelper "fullDateTime", (date) ->
  date = moment(date)
  if date.dayOfYear() is moment().dayOfYear()
    return "today #{date.format('HH:mm')}"
  else
    return date.format("DD.MM.YYYY HH:mm")

Template.registerHelper "fullDate", (date) ->
  date = moment(date)
  if date.dayOfYear() is moment().dayOfYear()
    return "today"
  else
    return date.format("DD.MM.YYYY")
