@getUserDescription = (user) ->
  if !user?
    return "unknown"
  if(name=user.profile.name)? and name.length > 0
    return name
  if(name=user.username)? and name.length > 0
    return name
  if user.emails and user.emails.length > 0
    return user.emails[0].address
  return user._id
