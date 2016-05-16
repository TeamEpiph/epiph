localizations = ['en', 'de', 'fr', 'it', 'es']
if Meteor.isClient
  Meteor.startup ->
    userLang = navigator.language || navigator.userLanguage
    userLang = userLang.slice(0,2)
    if localizations.indexOf(userLang) > -1
      moment.locale userLang
    else
      moment.locale 'en'

@__dateFormat = "L"
@__dateTimeFormat = "LLL"

@fullDate = (date) ->
  return null unless date?
  date = moment(date)
  formatted = date.format __dateFormat
  if Meteor.isClient
    if date.dayOfYear() is moment(TimeSync.serverTime()).dayOfYear()
      formatted += " (today)"
  formatted

if Meteor.isClient
  Template.registerHelper "fullDate", (date) ->
    fullDate(date)

@fullDateTime = (date)->
  return null unless date?
  date = moment(date)
  formatted = date.format __dateTimeFormat
  if Meteor.isClient
    if date.dayOfYear() is moment(TimeSync.serverTime()).dayOfYear()
      formatted += " (today)"
  formatted

if Meteor.isClient
  Template.registerHelper "fullDateTime", (date) ->
    fullDateTime(date)


@sanitizeDate = (val) ->
  val = val.replace '(', ''
  val = val.replace ')', ''
  val = val.replace 'today', ''
  val = val.trim()
  try
    date = moment(val, __dateFormat).toDate().getTime()
  catch e
    return null
  if isNaN(date)
    return null
  return date
