Template.editStudy.rendered = ->
  params = Router.current().params
  if !params.page
    Router.go "editStudy",
      _id: @data._id
      page: "editStudyPatients"
    
  
Template.editStudy.helpers
  titleEO: ->
    value: @title
    emptytext: "no title"
    success: (response, newVal) ->
      Studies.update self._id,
        $set: {title: newVal}
      return
  keyEO: ->
    value: @key
    emptytext: "no key"
    success: (response, newVal) ->
      Studies.update self._id,
        $set: {key: newVal}
      return

  tabs: ->
    [
      title: "Designs"
      template: "editStudyDesigns"
    ,
      title: "Patients"
      template: "editStudyPatients"
    ]

  #this tab
  tabClasses: ->
    params = Router.current().params
    return "" if !params? or !params.page?
    if @template is params.page
      return "active"
    ""

  template: ->
    Router.current().params.page
    
    
Template.editStudy.events
  "click .switchTab": (evt) ->
    _id = $(evt.target).data('id')
    Router.go "editStudy",
      _id: _id
      page: @template
    false
