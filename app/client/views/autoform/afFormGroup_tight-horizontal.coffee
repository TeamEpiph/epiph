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

  reallySkipLabel: ->
    reallySkipLabel = false
    if @name.indexOf('choices') > -1 or @name.indexOf('subquestions') > -1 
      if @name.indexOf('.0.') is -1
        reallySkipLabel = true
    reallySkipLabel
  myFormGroupClass: ->
    if @name.indexOf('choices') > -1
      if @name.indexOf('label') > -1
        "col-md-8"
      else if @name.indexOf('variable') > -1
        "col-md-2"
      else if @name.indexOf('value') > -1
        "col-md-2"
    else if @name.indexOf('subquestions') > -1 
      if @name.indexOf('code') > -1
        "col-md-2"
      else if @name.indexOf('label') > -1
        "col-md-10"
      else if @name.indexOf('minLabel') > -1
        "col-md-5"
      else if @name.indexOf('maxLabel') > -1
        "col-md-5"
    else
      ""
