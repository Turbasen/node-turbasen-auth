assert = require 'assert'
TurbasenAuth = require '../src/auth'

auth = groups = _getGroups = _getGroup = null

beforeEach ->
  auth = new TurbasenAuth('node-turbasen-auth/v1.0.0', process.env.NTB_API_KEY)
  groups = [{
    _id: '507f1f77bcf86cd799439011'
    navn: 'Foo Group'
    privat:
      brukere: [{
        _password: 'Pa$w0rd'
        navn: 'Foo Bar'
        epost: 'foo@bar.org'
        pbkdf2:
          prf: 'HMAC-SHA1'
          itrs: 100
          salt: 'XO6rZj9WG1UsLEsAGQH16qgZpCM9D7VylFQzwpSmOEo='
          dkLen: 32
          hash: 'Ir/5WTFgyBJoI3pJ8SaH8qWxdgZ0my6qcOPVPHnYJQ4='
      },{
        _password: 'Pik4chu'
        navn: 'Bar Foo'
        epost: 'bar@foo.org'
        pbkdf2:
          prf: 'HMAC-SHA1'
          itrs: 100
          salt: 'XO6rZj9WG1UsLEsAGQH16qgZpCM9D7VylFQzwpSmOEa='
          dkLen: 32
          hash: '7oVtqDGrHf48OUYXwY/3qJks1q40Wg8f+bo+FFAI7oA='
      },{
        navn: 'Baz Bar'
        epost: 'baz@bar.org'
      }]
  },{
    _id: '507f191e810c19729de860ea'
    navn: 'Bar Group'
    privat:
      brukere: [{
        _password: 'Pik4chu'
        navn: 'Baz Bar'
        epost: 'baz@bar.org'
        pbkdf2:
          prf: 'HMAC-SHA1'
          itrs: 100
          salt: 'XO6rZj9WG1UsLEsAGQH16qgZpCM9D7VylFQzwpSmOEa='
          dkLen: 32
          hash: '7oVtqDGrHf48OUYXwY/3qJks1q40Wg8f+bo+FFAI7oA='
      }]
  }]

  _getGroup = auth._getGroup
  _getGroups = auth._getGroups

  auth._getGroups = (email, cb) ->
    res = statusCode: 200
    body = documents: [], count: 0, total: 0

    switch email
      when "foo@bar.org" then body.documents.push groups[0]
      when "bar@foo.org" then body.documents.push groups[0]
      when "baz@bar.org"
        body.documents.push groups[0]
        body.documents.push groups[1]

    # @TODO remove private data from view

    body.count = body.total = body.documents.length

    cb null, res, body

  auth._getGroup = (id, cb) ->
    res = statusCode: 200
    body = {}

    switch id
      when "507f1f77bcf86cd799439011" then body = groups[0]
      when "507f191e810c19729de860ea" then body = groups[1]
      else
        res.statusCode = 404

    if Object.keys(body).length isnt 0
      delete body.privat.brukere[key]._password for _, key in body.privat.brukere

    cb null, res, body

describe 'Constructor', ->
  it 'should make new instance', ->
    assert auth instanceof TurbasenAuth

describe '#_authUsers()', ->
  users = []
  passwords = []

  beforeEach ->
    users = groups[0].privat.brukere
    for user, key in users
      passwords.push user._password
      delete users[key]._password

  it 'should return false if no match is found', (done) ->
    auth._authUsers 'some@user.org', 'P4s$word', users, (err, user) ->
      assert.equal user, false
      done()

  it 'should return true if a match is found', (done) ->
    auth._authUsers users[1].epost, passwords[1], users, (err, user) ->
      assert.deepEqual user,
        navn: users[1].navn
        epost: users[1].epost
      done()

describe '#_authGroup()', ->
  group = null
  beforeEach -> group = _id: 'abc123', navn: 'Awesome group'

  it 'should return error for non 404 error code', (done) ->
    auth._getGroup = (id, cb) -> cb null, statusCode: 501, {}
    auth._authGroup 'email', 'pass', group, (err, match) ->
      assert /HTTP_ERR GET \/gruppe\/abc123 - 501/.test err
      done()

  it 'should return false for HTTP error code is 404', (done) ->
    auth._getGroup = (id, cb) -> cb null, statusCode: 404, {}
    auth._authGroup 'email', 'pass', group, (err, match) ->
      assert.ifError err
      assert.equal match, false
      done()

  it 'should return false for no group user object', (done) ->
    auth._authGroup 'email', 'pass', group, (err, match) ->
      assert.ifError err
      assert.equal match, false
      done()

  #it 'should return false for unknown email', (done) ->
  #  email = groups[0].privat.brukere[0].epost + 'A'
  #  passw = groups[0].privat.brukere[0]._password
  #  group = _id: groups[0]._id

  #  auth._authGroup email, passw, group, (err, match) ->
  #    assert.ifError err
  #    assert.equal match, false
  #    done()

  #it 'should return false for invalid password', (done) ->
  #  email = groups[0].privat.brukere[0].epost
  #  passw = groups[0].privat.brukere[0]._password + 'A'
  #  group = _id: groups[0]._id

  #  auth._authGroup email, passw, group, (err, match) ->
  #    assert.ifError err
  #    assert.equal match, false
  #    done()

  it 'should return user credentials for matching email and password', (done) ->
    name  = groups[0].privat.brukere[0].navn
    email = groups[0].privat.brukere[0].epost
    passw = groups[0].privat.brukere[0]._password
    group = _id: groups[0]._id, navn: groups[0].navn

    auth._authGroup email, passw, group, (err, match) ->
      assert.ifError err
      assert.deepEqual match,
        navn: name
        epost: email
        gruppe: group
      done()

describe '_authGroups()', ->
  it 'should authenticate user ammong one matching group', (done) ->
    name  = groups[0].privat.brukere[0].navn
    email = groups[0].privat.brukere[0].epost
    passw = groups[0].privat.brukere[0]._password
    group = _id: groups[0]._id, navn: groups[0].navn

    auth._authGroups email, passw, [groups[0]], (err, user) ->
      assert.ifError err
      assert.deepEqual user,
        navn: name
        epost: email
        gruppe: group
      done()

  it 'should authenticate user ammong several matching groups', (done) ->
    name  = groups[0].privat.brukere[0].navn
    email = groups[0].privat.brukere[0].epost
    passw = groups[0].privat.brukere[0]._password
    group = _id: groups[0]._id, navn: groups[0].navn

    auth._authGroups email, passw, groups, (err, user) ->
      assert.ifError err
      assert.deepEqual user,
        navn: name
        epost: email
        gruppe: group
      done()

describe '#authenticate()', ->
  it 'should authenticate user with valid credentials', (done) ->
    if process.env.INTEGRATION_TEST is 'true'
      @timeout 10000

      auth._getGroups = _getGroups
      auth._getGroup = _getGroup

      name  = 'Destinasjon Trysil'
      email = process.env.INTEGRATION_TEST_EMAIL
      passw = process.env.INTEGRATION_TEST_PASSW
      group = _id: '52407f3c4ec4a138150001d7', navn: 'Destinasjon Trysil'

    else
      name  = groups[0].privat.brukere[0].navn
      email = groups[0].privat.brukere[0].epost
      passw = groups[0].privat.brukere[0]._password
      group = _id: groups[0]._id, navn: groups[0].navn

    auth.authenticate email, passw, (err, user) ->
      assert.ifError err
      assert.deepEqual user,
        navn: name
        epost: email
        gruppe: group
      done()

describe '#createUserAuth()', ->
  crypto = require '../src/crypto'

  name = email = pass = null

  beforeEach ->
    name = 'Foo Bar'
    email = 'foo@bar.org'
    pass = 'Pa$w0rd'

  it 'should create new user object', (done) ->
    auth.createUserAuth name, email, pass, (err, user) ->
      assert.ifError err
      assert.equal user.navn, name
      assert.equal user.epost, email

      assert.equal typeof user.pbkdf2, 'object'
      assert.equal typeof user.pbkdf2.salt, 'string'
      assert.equal typeof user.pbkdf2.hash, 'string'
      assert.equal user.pbkdf2.itrs, 131072
      assert.equal user.pbkdf2.dkLen, 256

      done()

  it 'should create valid authentication object', (done) ->
    @timeout 50000

    auth.createUserAuth name, email, pass, (err, user) ->
      assert.ifError err

      crypto.authenticate email, pass, user, (isAuth, code, msg) ->
        assert.equal isAuth, true
        assert.equal code, undefined
        assert.equal msg, undefined

        done()
