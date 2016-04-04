#work around autoform's missing defaultValues
textareaRendered = ->
  e = @$('textarea')[0]
  e.defaultValue = e.value
  return

Template.afTextarea.rendered = textareaRendered
Template.afTextarea_bootstrap3.rendered = textareaRendered


inputRendered = ->
  e = @$('input')[0]
  e.defaultValue = e.value
  return

Template.afInputNumber.rendered = inputRendered
Template.afInputNumber_bootstrap3.rendered = inputRendered

afBootstrapDatepickerRendered = Template.afBootstrapDatepicker.rendered
Template.afBootstrapDatepicker.rendered = ->
  afBootstrapDatepickerRendered.call @
  self = @
  @autorun ->
    data = Template.currentData()
    inputRendered.call self

afBootstrapDateTimePickerRendered = Template.afBootstrapDateTimePicker.rendered
Template.afBootstrapDateTimePicker.rendered = ->
  afBootstrapDateTimePickerRendered.call @
  self = @
  @autorun ->
    data = Template.currentData()
    inputRendered.call self
