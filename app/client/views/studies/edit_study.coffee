_isLocked = new ReactiveVar false

refreshOverlayPosition = ->
  if _isLocked.get()
    studyPage = $("#studyPage")
    studyPagePos = studyPage.position()
    $("#studyPageOverlay").css
      position: 'absolute'
      top: studyPagePos.top+1
      left: studyPagePos.left-10
      width: studyPage.width()+20
      bottom: 0
    $("#studyPageOverlay").show()
  else
    $("#studyPageOverlay").hide()
  return

Template.editStudy.destroyed = ->
  $(window).off("resize", refreshOverlayPosition)

Template.editStudy.rendered = ->
  params = Router.current().params
  if !params.page
    Router.go "editStudy",
      _id: @data._id
      page: "editStudyDesigns"
    ,
      replaceState: true

  @autorun ->
    data = Template.currentData()
    _isLocked.set data.isLocked
    refreshOverlayPosition()

  $(window).resize(refreshOverlayPosition)
  refreshOverlayPosition()
 
 
Template.editStudy.helpers
  titleEO: ->
    self = @
    value: @title
    emptytext: "no title"
    success: (response, newVal) ->
      Meteor.call "updateStudyTitle", self._id, newVal, (error) ->
        if error?
          $(".editStudy .x-editable-meteorized").editable('setValue', self.title)
          throwError error
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

  "click .lockStudy, click .unlockStudy": (evt) ->
    if $(evt.target).attr('class').indexOf("unlockStudy") > -1
      action = "unlock"
    else
      action = "lock"
    studyId = @_id
    swal {
      title: 'Need reason!'
      text: """Please state a reason why to #{action} this study. A log entry will be created."""
      type: 'input'
      showCancelButton: true
      confirmButtonText: 'Yes'
      inputPlaceholder: "Please state a reason."
      closeOnConfirm: false
    }, (confirmedWithReason)->
      if confirmedWithReason is false #cancel
        swal.close()
      else
        if !confirmedWithReason? or confirmedWithReason.length is 0
          swal.showInputError("You need to state a reason!")
        else
          Meteor.call "#{action}Study", studyId, confirmedWithReason, (error) ->
            if error?
              throwError error
            else
              swal.close()
      return
    false
