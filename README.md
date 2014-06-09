Nasjonal Turbase Auth [![Build Status](https://drone.io/github.com/Turistforeningen/node-turbasen-auth/status.png)](https://drone.io/github.com/Turistforeningen/node-turbasen-auth/latest)
=====================

[![NPM](https://nodei.co/npm/turbasen-auth.png)](https://nodei.co/npm/turbasen-auth/)

Authenticate group (grupper) users in Nasjonal Turbase with 0 effort. Just
install, and start using it.


## Requiremetns

1. Node.JS >= 0.10
2. Nasjonal Turbase API key

## Install

```
npm install turbasen-auth --save
```

## Test

### Unit tests

```
npm test
```

### Integration tests

As above with following environemtn variables set:

* `NTB_API_KEY` = your Nasjonal Turbase API key
* `INTEGRATION_TEST` = `true`
* `INTEGRATION_TEST_EMAIL` = valid group user email
* `INTEGRATION_TEST_PASSW` = valid group user password

## Usage

```javascript
var TurbasenAuth = require('turbasen-auth');
var client = new TurbasenAuth(appName, apiKey, options);
```

* `appName` name (and version) of your application
* `apiKey` your API key to Nasjonal Turbase
* `options`
  * `env` environment; may be `api` or `dev`.

### #uthenticate()
```javascript
client.authenticate(email, password, function(error, user) {
  if (error) {
    // Something went horrible wrong
    console.error(error);
  } else if (user) {
    console.log('Hello %s!', user.navn);
  } else {
    console.log('Authentication failed!');
  }
});
```

