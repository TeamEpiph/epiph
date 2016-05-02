appDump.allow = ->
  if @user? and Roles.userIsInRole(@user, 'admin')
    true
  else
    false
