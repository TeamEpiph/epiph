# show errors from method-update schema check
AutoForm.addHooks null,
  beginSubmit: ->
    AutoForm.templateInstanceForForm(@formId)._stickyErrors = {}
  onError: (formType, error) ->
    form = @
    try
      fieldErrors = JSON.parse(error.details)
    catch e
      # don't care
    finally
      if error.reason is "validationErrorQuestionInUse"
        AutoForm.resetForm form.formId
        throwError error
        return
      else if (!fieldErrors? or fieldErrors.length is 0) and !error.invalidKeys?
        throwError error
        return
    if fieldErrors?
      fieldErrors.forEach (e) ->
        form.addStickyValidationError(e.name, e.type)


# Fix null array items
# See https://github.com/aldeed/meteor-autoform/issues/840
AutoForm.addHooks null,
  before: update: (doc) ->
    _.each doc.$set, (value, setter) ->
      if _.isArray(value)
        newValue = _.compact(value)
        doc.$set[setter] = newValue
      return
    doc
  before: 'method-update': (doc) ->
    _.each doc.$set, (value, setter) ->
      if _.isArray(value)
        newValue = _.compact(value)
        doc.$set[setter] = newValue
      return
    doc
