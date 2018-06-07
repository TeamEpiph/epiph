@getUserDescription = (user) ->
  if !user?
    return "unknown"
  if user.profile? and user.profile.name? and user.profile.name.length > 0
    return user.profile.name
  if user.username? and user.username.length > 0
    return user.username
  if user.emails and user.emails.length > 0
    return user.emails[0].address
  return user._id
