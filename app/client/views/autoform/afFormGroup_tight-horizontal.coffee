Template['afFormGroup_tight-horizontal'].helpers
  afFieldInputAtts: ->
    atts = _.omit(@afFieldInputAtts or {}, 'input-col-class')
    # We have a special template for check boxes, but otherwise we
    # want to use the same as those defined for bootstrap3 template.
    if AutoForm.getInputType(@afFieldInputAtts) == 'boolean-checkbox'
      atts.template = 'bootstrap3-horizontal'
    else
      atts.template = 'bootstrap3'
    atts
  afFieldLabelAtts: ->
    atts = _.clone(@afFieldLabelAtts or {})
    # Add bootstrap class
    atts = AutoForm.Utility.addClass(atts, 'control-label')
    atts
  rightColumnClass: ->
    atts = @afFieldInputAtts or {}
    atts['input-col-class'] or ''
  skipLabel: ->
    self = this
    type = AutoForm.getInputType(self.afFieldInputAtts)
    self.skipLabel or type == 'boolean-checkbox' and !self.afFieldInputAtts.leftLabel

