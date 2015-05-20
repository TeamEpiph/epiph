@BeforeInsertTimestampHook = (userId, doc) ->
  doc.createdAt = Date.now()
  doc.updatedAt = doc.createdAt
  return

@BeforeUpdateTimestampHook = (userId, doc, fieldNames, modifier, options) ->
  modifier.$set = modifier.$set or {}
  modifier.$set.updatedAt = Date.now()
  return
