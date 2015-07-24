/*jshint node:true, mocha:true */
"use strict";

var express = require('express');
var bodyParser = require('body-parser');
var auth = require('../');

var app = module.exports = express();

app.use(bodyParser.json());

app.post('/authenticate', auth.middleware, function(req, res){
  if (req.turbasenAuth) {
    res.json(req.turbasenAuth);
  } else {
    res.status(401).json({authenticated: false});
  }
});

if (!module.parent) {
  app.listen(4000);
  console.log('Server is listening on port 4000');
}
