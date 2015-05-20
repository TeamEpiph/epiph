Accounts.validateLoginAttempt (attempt) ->
  if attempt.user?
    return Roles.userIsInRole(attempt.user, ['admin', 'therapist', 'analyst'])
  return false
