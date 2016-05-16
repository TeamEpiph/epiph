Accounts.validateLoginAttempt (attempt) ->
  if attempt.user?
    return Roles.userIsInRole(attempt.user, ['admin', 'caseManager'])
  return false
