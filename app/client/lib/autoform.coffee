# show errors from method-update schema check
AutoForm.addHooks null,
  beginSubmit: ->
    AutoForm.templateInstanceForForm(@formId)._stickyErrors = {}
  onError: (formType, error) ->
    try
      fieldErrors = JSON.parse(error.details)
    catch e
      # don't care
    finally
      if !fieldErrors? or fieldErrors.length is 0 
        throwError error
        return
    form = @
    JSON.parse(error.details).forEach (e) ->
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
