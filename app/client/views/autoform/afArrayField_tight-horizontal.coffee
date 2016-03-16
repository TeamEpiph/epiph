Template['afArrayField_tight-horizontal'].helpers
  rightColumnClass: ->
    atts = @atts or {}
    atts['input-col-class'] or ''
  afFieldLabelAtts: ->
    # Use only atts beginning with label-
    labelAtts = {}
    _.each @atts, (val, key) ->
      if key.indexOf('label-') == 0
        labelAtts[key.substring(6)] = val
      return
    # Add bootstrap class
    labelAtts = AutoForm.Utility.addClass(labelAtts, 'control-label')
    labelAtts


