@__getMongodbUsername = (user) ->
  user.emails[0].address.replace("@", "+")
