Router.configure
  layoutTemplate: "layout"
  loadingTemplate: "loading"
  notFoundTemplate: "not_found"

AccountsTemplates.configure
  defaultLayout: 'layout'
  enablePasswordChange: true
  showForgotPasswordLink: true

AccountsTemplates.configureRoute('changePwd');
AccountsTemplates.configureRoute('enrollAccount');
AccountsTemplates.configureRoute('forgotPwd');
AccountsTemplates.configureRoute('resetPwd');
AccountsTemplates.configureRoute('signIn', { redirect: '/patients', });
AccountsTemplates.configureRoute('signUp');
AccountsTemplates.configureRoute('verifyEmail');

pwd = AccountsTemplates.removeField('password');
AccountsTemplates.removeField('email');
AccountsTemplates.addFields([
  {
      _id: "username",
      type: "text",
      displayName: "username",
      required: true,
      minLength: 5,
  },
  {
      _id: 'email',
      type: 'email',
      required: true,
      displayName: "email",
      re: /.+@(.+){2,}\.(.+){2,}/,
      errStr: 'Invalid email',
  },
  pwd
]);

Router.plugin('ensureSignedIn', {
    except: ['atSignIn', 'atSignUp', 'atForgotPwd', 'atResetPwd']
});

previousPage = null
Router.map ->
  @route "root",
    path: "/"
    onBeforeAction: ->
      @redirect "/patients"

  @route "dashboard",
    path: "dashboard"

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

  @route "translateQuestionnaire",
    path: "questionnaires/translate/:_id"
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
        Meteor.subscribe("caseManagers")
        Meteor.subscribe("studyDesignsForStudy", @params._id )
        Meteor.subscribe("questionnaires")
      ]
    data: ->
      Studies.findOne {_id: @params._id}

  @route "export",
    path: "export"
    waitOn: ->
      [
        Meteor.subscribe("questionnaires")
        Meteor.subscribe("questions")
        Meteor.subscribe("studies")
        Meteor.subscribe("studyDesigns")
        Meteor.subscribe("patients")
        Meteor.subscribe("visits")
        Meteor.subscribe("caseManagers")
        Meteor.subscribe("exportTables")
      ]

  @route "users",
    path: "users"
    waitOn: ->
      [
        Meteor.subscribe("users")
      ]

  @route "activities",
    path: "activities"
    waitOn: ->
      [
        Meteor.subscribe("users")
        Meteor.subscribe("activities")
      ]


if Meteor.isClient
  Accounts.ui.config
    passwordSignupFields: 'USERNAME_AND_EMAIL'
