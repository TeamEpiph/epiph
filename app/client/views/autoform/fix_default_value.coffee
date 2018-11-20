#work around autoform's missing defaultValues
textareaRendered = ->
  self = @
  @autorun ->
    data = Template.currentData()
    e = self.$('textarea')[0]
    e.defaultValue = e.value
  return
Template.afTextarea.rendered = textareaRendered
Template.afTextarea_bootstrap3.rendered = textareaRendered


inputRendered = ->
  self = @
  @autorun ->
    data = Template.currentData()
    e = self.$('input')[0]
    e.defaultValue = e.value
  return
Template.afInputNumber.rendered = inputRendered
Template.afInputNumber_bootstrap3.rendered = inputRendered
Template.afInputText.rendered = inputRendered
Template.afInputText_bootstrap3.rendered = inputRendered


checkboxRendered = ->
  self = @
  @autorun ->
    data = Template.currentData()
    e = self.$('input[type=checkbox]')[0]
    e.defaultChecked = e.checked
  return
Template.afCheckbox.rendered = checkboxRendered
Template.afCheckbox_bootstrap3.rendered = checkboxRendered
Template['afCheckbox_bootstrap3-horizontal'].rendered = checkboxRendered

selectRendered = ->
  self = @
  @autorun ->
    data = Template.currentData()
    self.$('option').each ->
      @defaultSelected = @selected
      return true
  return
Template.afSelect.rendered = selectRendered
Template.afSelect_bootstrap3.rendered = selectRendered


checkedInputRendered = ->
  self = @
  @autorun ->
    data = Template.currentData()
    self.$('input').each ->
      @defaultChecked = @checked
      return true
  return
Template.afRadioGroupInline.rendered = checkedInputRendered
Template.afRadioGroupInline_bootstrap3.rendered = checkedInputRendered
Template.afCheckboxGroupInline.rendered = checkedInputRendered
Template.afCheckboxGroupInline_bootstrap3.rendered = checkedInputRendered

Template.afRadioGroup.rendered = checkedInputRendered
Template.afRadioGroup_bootstrap3.rendered = checkedInputRendered
Template.afCheckboxGroup.rendered = checkedInputRendered
Template.afCheckboxGroup_bootstrap3.rendered = checkedInputRendered
