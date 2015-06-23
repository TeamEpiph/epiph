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
        Meteor.subscribe("questions")
        Meteor.subscribe("userProfiles")
      ]

  @route "editQuestionnaire",
    path: "questionnaires/edit/:_id"
    waitOn: ->
      [
        Meteor.subscribe("questionnaires")
        Meteor.subscribe("questionsForQuestionnaire", @params._id)
      ]
    data: ->
      Questionnaires.findOne {_id: @params._id}


  @route "studies",
    path: "studies"
    waitOn: ->
      [
        Meteor.subscribe("studies")
        Meteor.subscribe("userProfiles")
      ]

  @route "editStudy",
    path: "studies/edit/:_id/:page?"
    waitOn: ->
      [
        Meteor.subscribe("study", @params._id )
        Meteor.subscribe("patientsForStudy", @params._id )
        Meteor.subscribe("therapists")	
      ]
    data: ->
      Studies.findOne {_id: @params._id}

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
    dashboardRoute: '/patients'  #redirect to this path after sign-in
    passwordSignupFields: 'USERNAME_AND_EMAIL'
