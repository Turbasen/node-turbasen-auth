crypto = require 'crypto'
request = require 'request'
async = require 'async'

TurbasenAuth = (client, key, opts) ->
  @client = client
  @key = key

  opts ?= {}
  opts.env ?= 'api'

  @url = "http://#{opts.env}.nasjonalturbase.no"

  @

TurbasenAuth.prototype._getGroups = (email, cb) ->
  request.get
    json: true
    uri: "#{@url}/grupper"
    qs: api_key: @key, "privat.brukere.epost": email
  , cb

TurbasenAuth.prototype._getGroup = (id, cb) ->
  request.get
    json: true
    uri: "#{@url}/grupper/#{id}"
    qs: api_key: @key
  , cb

TurbasenAuth.prototype._authUser = (email, password, user, cb) ->
  return cb false if email isnt user.epost
  return cb false if not user.pbkdf2
  return cb false if not user.pbkdf2?.prf? is 'HMAC-SHA1'

  pwd = new Buffer password, 'utf8'
  salt = new Buffer user.pbkdf2.salt, 'base64'
  itrs = user.pbkdf2.itrs
  dkLen = user.pbkdf2.dkLen

  crypto.pbkdf2 pwd, salt, itrs, dkLen, (err, hash) ->
    return cb false if err
    return cb hash.toString('base64') is user.pbkdf2.hash

TurbasenAuth.prototype._authUsers = (email, password, users, cb) ->
  iterator = async.apply @_authUser.bind(@), email, password
  async.detect users, iterator, (user) ->
    delete user.pbkdf2 if user?.pbkdf2

    cb null, user or false

TurbasenAuth.prototype._authGroup = (email, password, group, cb) ->
  @_getGroup group._id, (err, res, body) =>
    return cb err if err
    if res.statusCode not in [404, 200]
      return cb new Error("HTTP_ERR GET /gruppe/#{group._id} - #{res.statusCode}")
    return cb null, false if res.statusCode is 404 or not body?.privat?.brukere

    @_authUsers email, password, body.privat.brukere, (err, user) ->
      user.gruppe = _id: group._id, navn: (group.navn or 'Gruppe uten navn') if user
      return cb err, user

TurbasenAuth.prototype._authGroups = (email, password, groups, cb) ->
  iterator = async.apply @_authGroup.bind(@), email, password
  async.map groups, iterator, (err, groups) ->
    return cb err if err
    return cb(null, group) for group in groups when group isnt false
    cb null, false

TurbasenAuth.prototype.authenticate = (email, password, cb) ->
  @_getGroups email, (err, res, body) =>
    return cb err if err
    return cb new Error('Error code ' + res.statusCode) if res.statusCode isnt 200
    return cb null, false if body.documents.length is 0

    @_authGroups email, password, body.documents, cb

module.exports = TurbasenAuth

