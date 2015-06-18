assert = require 'assert'
crypto = require '../src/crypto'

user = null

beforeEach ->
  user =
    _password: 'Pa$w0rd'
    navn: 'Foo Bar'
    epost: 'foo@bar.org'
    pbkdf2:
      prf: 'HMAC-SHA1'
      itrs: 100
      salt: 'XO6rZj9WG1UsLEsAGQH16qgZpCM9D7VylFQzwpSmOEo='
      dkLen: 32
      hash: 'Ir/5WTFgyBJoI3pJ8SaH8qWxdgZ0my6qcOPVPHnYJQ4='

describe 'pbkdf2()', ->
  it 'returns pbkdf2 hash', (done) ->
    pwd     = user._password
    itrs    = user.pbkdf2.itrs
    dkLen   = user.pbkdf2.dkLen
    salt    = user.pbkdf2.salt
    hash    = user.pbkdf2.hash

    crypto.pbkdf2 pwd, salt, itrs, dkLen, (err, h) ->
      assert.ifError err
      assert.equal h, hash
      done()

describe 'salt()', ->
  it 'returns random salt', ->
    assert.equal crypto.salt().length, 172
    assert.notEqual crypto.salt(), crypto.salt()

describe 'authenticate()', ->
  it 'returns true for correct email and password', (done) ->
    email = user.epost
    pass  = user._password

    crypto.authenticate email, pass, user, (isAuth, code, msg) ->
      assert.equal isAuth, true
      assert.equal code, undefined
      assert.equal msg, undefined

      done()

  it 'returns code AUTH001 when email does not match', (done) ->
    email = 'foo'
    pass  = user._password

    crypto.authenticate email, pass, user, (isAuth, code, msg) ->
      assert.equal isAuth, false
      assert.equal code, 'AUTH001'
      assert.equal msg, 'User email did not match'

      done()

  it 'returns code AUTH002 for invalid auth schema', (done) ->
    email = user.epost
    pass  = user._password
    user.pbkdf2 = undefined

    crypto.authenticate email, pass, user, (isAuth, code, msg) ->
      assert.equal isAuth, false
      assert.equal code, 'AUTH002'
      assert.equal msg, 'Unknown authentication schema'

      done()

  it 'returns code AUTH003 when pbkdf2 fails', (done) ->
    email = user.epost
    pass  = user._password
    user.pbkdf2.dkLen = -1

    crypto.authenticate email, pass, user, (isAuth, code, msg) ->
      assert.equal isAuth, false
      assert.equal code, 'AUTH003'
      assert /TypeError: Bad key length/.test msg
      done()

  it 'returns code AUTH004 when hash does not match', (done) ->
    email = user.epost
    pass  = 'foo'

    crypto.authenticate email, pass, user, (isAuth, code, msg) ->
      assert.equal isAuth, false
      assert.equal code, 'AUTH004'
      assert.equal msg, 'User password hash did not match'

      done()
