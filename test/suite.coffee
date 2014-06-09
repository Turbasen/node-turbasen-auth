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

describe 'TurbasenAuth', ->
  it 'should make new instance', ->
    assert auth instanceof TurbasenAuth

  describe '#_authUser()', ->
    user = pass = null

    beforeEach ->
      user = groups[0].privat.brukere[0]
      pass = user._password
      delete user._password

    it 'should return false if input email is missing', (done) ->
      auth._authUser undefined, pass, user, (auth) ->
        assert.equal auth, false
        done()

    it 'should return false if input password is missing', (done) ->
      auth._authUser user.email, undefined, user, (auth) ->
        assert.equal auth, false
        done()

    it 'should return false if user authenticate isnt supported', (done) ->
      delete user.pbkdf2
      auth._authUser user.email, pass, user, (auth) ->
        assert.equal auth, false
        done()

    it 'should return false if pseudorandom function isnt supported', (done) ->
      user.pbkdf2.prf = 'HMAC-SHA256'
      auth._authUser user.email, pass, user, (auth) ->
        assert.equal auth, false
        done()

    it 'should return false for inavlid user password', (done) ->
      auth._authUser user.email, 'Password', user, (auth) ->
        assert.equal auth, false
        done()

    it 'should return false for matching user password', (done) ->
      auth._authUser user.epost, pass, user, (auth) ->
        assert.equal auth, true
        done()

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
    it 'should return error for non 404 error code', (done) ->
      auth._getGroup = (id, cb) -> cb null, statusCode: 501, {}
      auth._authGroup 'email', 'pass', _id: 'abc123', (err, match) ->
        assert /HTTP_ERR GET \/gruppe\/abc123 - 501/.test err
        done()

    it 'should return false for HTTP error code is 404', (done) ->
      auth._getGroup = (id, cb) -> cb null, statusCode: 404, {}
      auth._authGroup 'email', 'pass', _id: 'abc123', (err, match) ->
        assert.ifError err
        assert.equal match, false
        done()

    it 'should return false for no group user object', (done) ->
      auth._authGroup 'email', 'pass', _id: 'abc123', (err, match) ->
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
      email = groups[0].privat.brukere[0].epost
      passw = groups[0].privat.brukere[0]._password
      group = _id: groups[0]._id

      auth._authGroup email, passw, group, (err, match) ->
        assert.ifError err
        assert.deepEqual match,
          navn: groups[0].privat.brukere[0].navn
          epost: groups[0].privat.brukere[0].epost
        done()

  describe '_authGroups()', ->
    it 'should authenticate user ammong one matching group', (done) ->
      email = groups[0].privat.brukere[0].epost
      passw = groups[0].privat.brukere[0]._password

      auth._authGroups email, passw, [groups[0]], (err, user) ->
        assert.ifError err
        assert.deepEqual user,
          navn: groups[0].privat.brukere[0].navn
          epost: groups[0].privat.brukere[0].epost
        done()

    it 'should authenticate user ammong several matching groups', (done) ->
      email = groups[0].privat.brukere[0].epost
      passw = groups[0].privat.brukere[0]._password

      auth._authGroups email, passw, groups, (err, user) ->
        assert.ifError err
        assert.deepEqual user,
          navn: groups[0].privat.brukere[0].navn
          epost: groups[0].privat.brukere[0].epost
        done()

  describe '#authenticate()', ->
    it 'should get groups', (done) ->
      if process.env.INTEGRATION_TEST is 'true'
        @timeout 10000

        auth._getGroups = _getGroups
        auth._getGroup = _getGroup

        name  = 'Destinasjon Trysil'
        email = process.env.INTEGRATION_TEST_EMAIL
        passw = process.env.INTEGRATION_TEST_PASSW

      else
        name  = groups[0].privat.brukere[0].navn
        email = groups[0].privat.brukere[0].epost
        passw = groups[0].privat.brukere[0]._password

      auth.authenticate email, passw, (err, user) ->
        assert.ifError err
        assert.deepEqual user,
          navn: name
          epost: email
        done()

