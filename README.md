# Nasjonal Turbase Auth

[![Build status](https://img.shields.io/wercker/ci/5581217caf7de9c51b009114.svg "Build status")](https://app.wercker.com/project/bykey/e28d2f6246e21a84b55d918440358648)
[![NPM downloads](https://img.shields.io/npm/dm/turbasen-auth.svg "NPM downloads")](https://www.npmjs.com/package/turbasen-auth)
[![NPM version](https://img.shields.io/npm/v/turbasen-auth.svg "NPM version")](https://www.npmjs.com/package/turbasen-auth)
[![Node version](https://img.shields.io/node/v/turbasen-auth.svg "Node version")](https://www.npmjs.com/package/turbasen-auth)
[![Dependency status](https://img.shields.io/david/turistforeningen/node-turbasen-auth.svg "Dependency status")](https://david-dm.org/turistforeningen/node-turbasen-auth)

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

```
npm test
```

## Usage

```javascript
var TurbasenAuth = require('turbasen-auth');
var client = new TurbasenAuth(appName, apiKey, options);
```

* `appName` name (and version) of your application
* `apiKey` your API key to Nasjonal Turbase
* `options`
  * `env` environment; may be `api` or `dev`.

### client.authenticate()

Authenticate user against Nasjonal Turbase.

#### Params

* `string` email - user email
* `string` password - user password
* `string` callback - callback function (`Error` error, `object` user)

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

### client.createUserAuth()

Create user authentication object for storate in Nasjonal Turbase.

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
  "pbkdf2:
    "prf": 'HMAC-SHA1',
    "itrs": 131072,
    "salt": "XO6rZj9WG1UsLEsAGQH16qgZpCM9D7VylFQzwpSmOEo=",
    "dkLen": 256,
    "hash": "Ir/5WTFgyBJoI3pJ8SaH8qWxdgZ0my6qcOPVPHnYJQ4="
  }
}
```

#### Example

```javascript
client.createUserAuth(name, email, password, function(error, user) {
  if (error) {
    throw error;
  }

  console.log(user);
  }
});
```

## [MIT Licensed](https://github.com/Turistforeningen/node-turbasen-auth/blob/master/LICENSE)
