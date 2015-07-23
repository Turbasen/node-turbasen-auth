/*jshint node:true */
"use strict";

var async = require('async');
var turbasen = require('turbasen');
var crypto = require('./lib/crypto');

module.exports._authGroup = function(email, password, group, cb) {
  turbasen.grupper.get(group._id, function(err, res, body) {
    if (err) { return cb(err); }

    if (res.statusCode !== 200) {
      return cb(new Error('AUTH102: Error code ' + res.statusCode));
    }

    var iterator = async.apply(crypto.authenticate, email, password);
    async.detect(body.privat.brukere, iterator, function(user) {
      if (!user) {
        return cb(null, false);
      }

      return cb(null, {
        navn: user.navn,
        epost: user.epost,
        gruppe: group
      });
    });
  });
};

module.exports.authenticate = function(email, password, cb) {
  turbasen.grupper({'privat.brukere.epost': email}, function(err, res, body) {
    if (err) { return cb(err); }

    if (res.statusCode !== 200) {
      return cb(new Error('AUTH101: Error code ' + res.statusCode));
    }

    if (body.documents.length === 0) {
      return cb(null, false);
    }

    var iterator = async.apply(module.exports._authGroup, email, password);
    async.map(body.documents, iterator, function(err, groups) {
      if (err) { return cb(err); }

      for (var i = 0; i < groups.length; i++) {
         if (groups[i]) {
          return cb(null, groups[i]);
        }
      }

      return cb(null, false);
    });
  });
};

module.exports.createUserAuth = function(name, email, pass, cb) {

};

module.exports.middleware = function(req, res, next) {
  var email = req.body.email;
  var password = req.body.password;

  if (email && password) {
    module.exports.authenticate(email, password, function(err, user) {
      req.turbasenAuth = user;
      next(err);
    });
  } else {
    return process.nextTick(function() { next(); });
  }
};

module.exports.turbasen = turbasen;
