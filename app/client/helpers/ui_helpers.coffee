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
  fullDateTime(date)

@fullDateTime = (date)->
  return null unless date?
  date = moment(date)
  if date.dayOfYear() is moment(TimeSync.serverTime()).dayOfYear()
    return "today #{date.format('HH:mm')}"
  else
    return date.format("DD.MM.YYYY HH:mm")

Template.registerHelper "fullDate", (date) ->
  return null unless date?
  date = moment(date)
  if date.dayOfYear() is moment(TimeSync.serverTime()).dayOfYear()
    return "today"
  else
    return date.format("DD.MM.YYYY")

Template.registerHelper "agoOrDateTime", (date) ->
  return null unless date?
  date = moment(date)
  if date.diff(TimeSync.serverTime(), 'days') < 11
    return date.fromNow()
  if date.dayOfYear() is moment().dayOfYear()
    return "today #{date.format('HH:mm')}"
  else
    return date.format("DD.MM.YYYY HH:mm")

Template.registerHelper "fileSizeSani", (size) ->
  if size > 1000
    "#{(size/1000).toFixed(1)} kB"
  else if size > 1000000
    "#{(size/1000000).toFixed(1)} MB"
  else if size > 1000000000
    "#{(size/1000000000).toFixed(1)} GB"
  else
    "#{(size)} B"

