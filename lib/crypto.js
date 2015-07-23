/*jshint node:true */
"use strict";

var crypto = require('crypto');

module.exports.pbkdf2 = function(pwd, salt, itrs, dkLen, cb) {
  pwd = new Buffer(pwd, 'utf8');
  salt = new Buffer(salt, 'base64');

  try {
    crypto.pbkdf2(pwd, salt, itrs, dkLen, function(err, hash) {
      cb(err, hash !== null ? hash.toString('base64') : undefined);
    });
  } catch (err) {
    process.nextTick(function() { cb(err); });
  }
};

module.exports.salt = function(length) {
  return crypto.randomBytes(length || 128).toString('base64');
};

module.exports.authenticate = function(email, pass, user, cb) {
  if (email !== user.epost) {
    return process.nextTick(function() {
      cb(false, 'AUTH001', 'User email did not match');
    });
  }

  if (!user.pbkdf2 || user.pbkdf2.prf !== 'HMAC-SHA1') {
    return process.nextTick(function() {
      cb(false, 'AUTH002', 'Unknown authentication schema');
    });
  }

  var salt = user.pbkdf2.salt;
  var itrs = user.pbkdf2.itrs;
  var dkLen = user.pbkdf2.dkLen;

  module.exports.pbkdf2(pass, salt, itrs, dkLen, function(err, hash) {
    if (err) { return cb(false, 'AUTH003', err); }

    if (hash === user.pbkdf2.hash) {
      cb(true);
    } else {
      cb(false, 'AUTH004', 'User password hash did not match');
    }
  });
};
