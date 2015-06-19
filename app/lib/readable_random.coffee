@readableRandom = (len)->
  random = ''
  charset = 'abcdefghjkmnpqrstuvwxyz123456789'
  i = 0
  while i < len
    random += charset.charAt(Math.floor(Math.random() * charset.length))
    i++
  random
