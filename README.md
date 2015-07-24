# Nasjonal Turbase Auth

[![Build status](https://img.shields.io/wercker/ci/55b1eaf74edd0c2278030492.svg "Build status")](https://app.wercker.com/project/bykey/5240bd0a4c5f609c832494e9dd18aefb)
[![NPM downloads](https://img.shields.io/npm/dm/turbasen-auth.svg "NPM downloads")](https://www.npmjs.com/package/turbasen-auth)
[![NPM version](https://img.shields.io/npm/v/turbasen-auth.svg "NPM version")](https://www.npmjs.com/package/turbasen-auth)
[![Node version](https://img.shields.io/node/v/turbasen-auth.svg "Node version")](https://www.npmjs.com/package/turbasen-auth)
[![Dependency status](https://img.shields.io/david/turistforeningen/node-turbasen-auth.svg "Dependency status")](https://david-dm.org/turistforeningen/node-turbasen-auth)

Authenticate group (grupper) users in Nasjonal Turbase with 0 effort. Just
install, and start using it.

## Requirements

1. Node.JS >= 0.10
2. Nasjonal Turbase API key

## Install

```
npm install turbasen-auth --save
```

## Test

```
npm test
```

## Usage

```js
var auth = require('turbasen-auth');
```

### Configure

This package uses the official Node.JS library for Nasjonal Turbase
([turbasen.js](https://github.com/Turbasen/turbasen.js)) which can be fully
configured using the environment variables:

* `NTB_API_KEY` - API key for authenticate requests
* `NTB_API_ENV` - API environment (default api, can be dev)
* `NTB_USER_AGENT` - User Agent for API requests

You can also set or update the configuration programmatically using the
[`auth.turbasen.configure()`](https://github.com/Turbasen/turbasen.js#configure)
method.

### auth.authenticate()

Authenticate user against Nasjonal Turbase.

#### Params

* `string` **email** - user email
* `string` **password** - user password
* `string` **callback** - callback function (`Error` **error**, `object` **user**)

#### Return

The returned user object contains `navn` (name), `epost` (email), and `gruppe`
(group).

```json
{
  "navn": "Foo User Name",
  "epost": "foo@bar.com",
  "gruppe": {
    "_id": "54759eb3c090d83494e2d804",
    "navn": "Bix Group Name"
  }
}
```

#### Example

```js
auth.authenticate(email, password, function(error, user) {
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

### auth.middleware()

A Connect / Express compatible middleware to make authentication super easy.

#### Body Params

The following params must be sent as JSON in the request body.

* `string` **email** - user email
* `string` **password** - user password

### Return

If the authentication succeeds the user information (identical to
`authenticate()`) will be available in the `req.turbasenAuth` variable.

### Example

See [server.js](examples/server.js) for a complete Express example.

```js
app.post('/auth', auth.middleware, function(req, res){
  // req.turbasenAuth
});
```

### auth.createUserAuth()

Create user authentication object for storage in Nasjonal Turbase.

#### Params

* `string` **name** - user name
* `string` **email** - user email
* `string` **password** - user password
* `string` **callback** - callback function (`Error` **error**, `object` **user**)

#### Return

The returned user object contains `navn` (name), `epost` (email), and `pbkdf2`
(user authentication).

```json
{
  "navn": "Foo User Name",
  "epost": "foo@bar.com",
  "pbkdf2": {
    "prf": "HMAC-SHA1",
    "itrs": 131072,
    "salt": "XO6rZj9WG1UsLEsAGQH16qgZpCM9D7VylFQzwpSmOEo=",
    "dkLen": 256,
    "hash": "Ir/5WTFgyBJoI3pJ8SaH8qWxdgZ0my6qcOPVPHnYJQ4="
  }
}
```

#### Example

```js
auth.createUserAuth(name, email, password, function(error, user) {
  if (error) {
    throw error;
  }

  console.log(user);
  }
});
```

## [MIT Licensed](https://github.com/Turistforeningen/node-turbasen-auth/blob/master/LICENSE)
