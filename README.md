Nasjonal Turbase Auth [![Build Status](https://drone.io/github.com/Turistforeningen/node-turbasen-auth/status.png)](https://drone.io/github.com/Turistforeningen/node-turbasen-auth/latest)
=====================

[![NPM](https://nodei.co/npm/turbasen-auth.png?downloads=true)](https://www.npmjs.com/package/turbasen-auth)

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

The returned user object will contains `navn` (name), `epost` (email), and
`gruppe` (group).

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

## [MIT Licensed](https://github.com/Turistforeningen/node-turbasen-auth/blob/master/LICENSE)

