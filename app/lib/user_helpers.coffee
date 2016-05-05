@getUserDescription = (user) ->
  if !user?
    return "unknown"
  if(name=user.profile.name) 
    return name
  if user.emails?length > 0
    return user.emails[0].address
  return user._id
