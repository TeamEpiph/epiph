@__findUnique = (Collection, field, oldId) ->
  if Collection.find("#{field}": oldId).count() is 0
    return oldId
  matches = /(.*)_(\d*)$/.exec oldId
  if !matches?
    name = oldId
    counter = 1
  else
    name = matches[1]
    counter = parseInt(matches[2])
  while Collection.find("#{field}": "#{name}_#{counter}").count() > 0
    counter += 1
  return "#{name}_#{counter}"
