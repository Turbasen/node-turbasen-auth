crypto = require 'crypto'

module.exports.pbkdf2 = (pwd, salt, itrs, dkLen, cb) ->
  pwd = new Buffer pwd, 'utf8'
  salt = new Buffer salt, 'base64'

  try
    crypto.pbkdf2 pwd, salt, itrs, dkLen, (err, hash) ->
      cb err, hash?.toString 'base64'
  catch err
    process.nextTick -> cb err

module.exports.salt = (length) ->
  crypto.randomBytes(length or 128).toString 'base64'

module.exports.authenticate = (email, pass, user, cb) ->
  if email isnt user.epost
    return process.nextTick ->
      cb false, 'AUTH001', 'User email did not match'

  if user.pbkdf2?.prf isnt 'HMAC-SHA1'
    return process.nextTick ->
      cb false, 'AUTH002', 'Unknown authentication schema'

  salt = user.pbkdf2.salt
  itrs = user.pbkdf2.itrs
  dkLen = user.pbkdf2.dkLen

  module.exports.pbkdf2 pass, salt, itrs, dkLen, (err, hash) ->
    return cb false, 'AUTH003', err if err
    if hash isnt user.pbkdf2.hash
      return cb false, 'AUTH004', 'User password hash did not match'

    return cb true
