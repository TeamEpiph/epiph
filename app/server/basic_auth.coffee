if process.env.BASIC_AUTH
  basicAuth = new HttpBasicAuth("freud", "1856")
  basicAuth.protect()
