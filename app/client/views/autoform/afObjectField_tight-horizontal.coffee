Template['afObjectField_tight-horizontal'].helpers
  rightColumnClass: ->
    @['input-col-class'] or ''
  afFieldLabelAtts: ->
    # Use only atts beginning with label-
    labelAtts = {}
    _.each this, (val, key) ->
      if key.indexOf('label-') == 0
        labelAtts[key.substring(6)] = val
      return
    # Add bootstrap class
    labelAtts = AutoForm.Utility.addClass(labelAtts, 'control-label')
    labelAtts
  quickFieldsAtts: ->
    atts = _.pick(this, 'name', 'id-prefix')
    # We want to default to using bootstrap3 template below this point
    # because we don't want horizontal within horizontal
    atts.template = 'tight-horizontal'
    atts

