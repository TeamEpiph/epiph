Template.editStudy.rendered = ->
  params = Router.current().params
  if !params.page
    Router.go "editStudy",
      _id: @data._id
      page: "editStudyDesigns"
    
  
Template.editStudy.helpers
  titleEO: ->
    self = @
    value: @title
    emptytext: "no title"
    success: (response, newVal) ->
      Meteor.call 'changeStudyTitle', self._id, newVal, (error) ->
        throwError error if error?
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
