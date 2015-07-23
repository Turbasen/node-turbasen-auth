/*jshint node:true, mocha:true */
"use strict";

var assert = require('assert');
var crypto = require('./lib/crypto');
var auth = require('./index');

process.env.NTB_USER_AGENT = 'turbasen-auth/v' + require('./package.json').version;

describe('lib/crypto', function() {
  var user = null;

  beforeEach(function() {
    user = {
      _password: 'Pa$w0rd',
      navn: 'Foo Bar',
      epost: 'foo@bar.org',
      pbkdf2: {
        prf: 'HMAC-SHA1',
        itrs: 100,
        salt: 'XO6rZj9WG1UsLEsAGQH16qgZpCM9D7VylFQzwpSmOEo=',
        dkLen: 32,
        hash: 'Ir/5WTFgyBJoI3pJ8SaH8qWxdgZ0my6qcOPVPHnYJQ4='
      }
    };
  });

  describe('pbkdf2()', function() {
    it('returns pbkdf2 hash', function(done) {
      var pwd = user._password;
      var itrs = user.pbkdf2.itrs;
      var dkLen = user.pbkdf2.dkLen;
      var salt = user.pbkdf2.salt;
      var hash = user.pbkdf2.hash;

      crypto.pbkdf2(pwd, salt, itrs, dkLen, function(err, h) {
        assert.ifError(err);
        assert.equal(h, hash);
        done();
      });
    });
  });

  describe('salt()', function() {
    it('returns random salt', function() {
      assert.equal(crypto.salt().length, 172);
      assert.notEqual(crypto.salt(), crypto.salt());
    });
  });

  describe('authenticate()', function() {
    it('returns true for correct email and password', function(done) {
      var email = user.epost;
      var pass = user._password;

      crypto.authenticate(email, pass, user, function(isAuth, code, msg) {
        assert.equal(isAuth, true);
        assert.equal(code, undefined);
        assert.equal(msg, undefined);
        done();
      });
    });

    it('returns code AUTH001 when email does not match', function(done) {
      var email = 'foo';
      var pass = user._password;

      crypto.authenticate(email, pass, user, function(isAuth, code, msg) {
        assert.equal(isAuth, false);
        assert.equal(code, 'AUTH001');
        assert.equal(msg, 'User email did not match');
        done();
      });
    });

    it('returns code AUTH002 for invalid auth schema', function(done) {
      var email = user.epost;
      var pass = user._password;
      user.pbkdf2 = undefined;

      crypto.authenticate(email, pass, user, function(isAuth, code, msg) {
        assert.equal(isAuth, false);
        assert.equal(code, 'AUTH002');
        assert.equal(msg, 'Unknown authentication schema');
        done();
      });
    });

    it('returns code AUTH003 when pbkdf2 fails', function(done) {
      var email = user.epost;
      var pass = user._password;
      user.pbkdf2.dkLen = -1;

      crypto.authenticate(email, pass, user, function(isAuth, code, msg) {
        assert.equal(isAuth, false);
        assert.equal(code, 'AUTH003');
        assert(/TypeError: Bad key length/.test(msg));
        done();
      });
    });

    it('returns code AUTH004 when hash does not match', function(done) {
      var email = user.epost;
      var pass = 'foo';

      crypto.authenticate(email, pass, user, function(isAuth, code, msg) {
        assert.equal(isAuth, false);
        assert.equal(code, 'AUTH004');
        assert.equal(msg, 'User password hash did not match');
        done();
      });
    });
  });
});

describe('#authenticate()', function() {
  var _user;

  beforeEach(function() {
    _user = {
      _password: process.env.INTEGRATION_TEST_PASSW,
      navn: process.env.INTEGRATION_TEST_NAME,
      epost: process.env.INTEGRATION_TEST_EMAIL,
      gruppe: {
        _id: '52407f3c4ec4a138150001d7',
        navn: 'Destinasjon Trysil'
      }
    };
  });

  it('should return false for invalid user email', function(done) {
    this.timeout(5000);

    auth.authenticate('foo@bar.com', _user._password, function(err, user) {
      assert.ifError(err);
      assert.equal(user, false);
      done();
    });
  });

  it('should return false for invalid user password', function(done) {
    this.timeout(5000);

    auth.authenticate(_user.epost, 'foobar', function(err, user) {
      assert.ifError(err);
      assert.equal(user, false);
      done();
    });
  });

  it('should return user data for valid user credentials', function(done) {
    this.timeout(5000);

    auth.authenticate(_user.epost, _user._password, function(err, user) {
      assert.ifError(err);
      assert.equal(user.navn, _user.navn);
      assert.equal(user.epost, _user.epost);
      assert.equal(user.gruppe._id, _user.gruppe._id);
      assert.equal(user.gruppe.navn, _user.gruppe.navn);
      done();
    });
  });
});

describe.only('#middleware()', function() {
  this.timeout(10000);
  var agent = require('supertest').agent(require('./examples/server'));

  it('should return 401 for invalid user credentials', function(done) {
    agent.post('/authenticate')
      .send({email: 'foo', password: 'bar'})
      .expect(401, done);
  });

  it('should return 200 for valid user credentials', function(done) {
    var email = process.env.INTEGRATION_TEST_EMAIL;
    var passw = process.env.INTEGRATION_TEST_PASSW;

    agent.post('/authenticate')
      .send({email: email, password: passw})
      .expect(200, done);
  });
});

describe('#createUserAuth()', function() {

});
