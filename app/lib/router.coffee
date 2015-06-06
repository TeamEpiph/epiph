Router.configure
  layoutTemplate: "layout"
  loadingTemplate: "loading"
  notFoundTemplate: "not_found"

# automatically render notFoundTemplate if data is null
#Router.onBeforeAction('dataNotFound')
Router.onBeforeAction( ->
  AccountsEntry.signInRequired(this)	
, {except: ["entrySignIn", "entrySignUp", "entryForgotPassword", "entrySignOut", "entryResetPassword"] })

#Router.plugin('ensureSignedIn',
#  except: ["entrySignIn", "entrySignUp", "entryForgotPassword", "entrySignOut", "entryResetPassword"]
#)

previousPage = null
Router.map ->
  @route "root",
    path: "/"
    onBeforeAction: (pause)->
      @redirect "/patients"

  @route "patients",
    path: "patients"
    waitOn: ->
      [
        Meteor.subscribe("patients")
      ]

  @route "questionnaires",
    path: "questionnaires"
    waitOn: ->
      [
        Meteor.subscribe("questionnaires")
      ]

  @route "editQuestionnaire",
    path: "questionnaires/edit/:_id"
    waitOn: ->
      [
        Meteor.subscribe("questionnaires")
        Meteor.subscribe("questions", @params._id)
      ]
    data: ->
      Questionnaires.findOne {_id: @params._id}


  @route "users",
    path: "users"
    waitOn: ->
      [
        Meteor.subscribe("users")
      ]


if Meteor.isClient	
  Router.onBeforeAction ->
    clearErrors()
    @next()
    return
  Accounts.ui.config
    passwordSignupFields: 'USERNAME_AND_EMAIL'

Meteor.startup ->
  AccountsEntry.config
    homeRoute: '/' #redirect to this path after sign-out
    dashboardRoute: '/dashboard'  #redirect to this path after sign-in
    passwordSignupFields: 'USERNAME_AND_EMAIL'
