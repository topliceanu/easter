# Easter

## Gist

**easter** is a RabbitMQ publish/subscribe client with support for both AMQP and HTTP protocols.

## Status

[![NPM](https://nodei.co/npm/easter.png?downloads=true&stars=true)](https://nodei.co/npm/easter/)

[![NPM](https://nodei.co/npm-dl/easter.png?months=12)](https://nodei.co/npm-dl/easter/)

| Indicator              |                                                                          |
|:-----------------------|:-------------------------------------------------------------------------|
| documentation          | [topliceanu.github.io/easter](http://topliceanu.github.io/easter) |
| continuous integration | [![Build Status](https://travis-ci.org/topliceanu/easter.svg?branch=master)](https://travis-ci.org/topliceanu/easter) |
| dependency management  | [![Dependency Status](https://david-dm.org/topliceanu/easter.svg?style=flat)](https://david-dm.org/topliceanu/easter) [![devDependency Status](https://david-dm.org/topliceanu/easter/dev-status.svg?style=flat)](https://david-dm.org/topliceanu/easter#info=devDependencies) |
| code coverage          | [![Coverage Status](https://coveralls.io/repos/topliceanu/easter/badge.svg?branch=master)](https://coveralls.io/r/topliceanu/easter?branch=master) |
| examples               | [/examples](https://github.com/topliceanu/easter/tree/master/examples) |
| change log             | [CHANGELOG](https://github.com/topliceanu/easter/blob/master/CHANGELOG.md) [Releases](https://github.com/topliceanu/easter/releases) |

## Features

- Simple API, just a `publish()` and a `subscribe()`
- Support for AMQP and HTTP apis.
- Transparent queue creation and management.

## Install

```shell
npm install easter
```

## Quick Example

```javascript
```

More examples are in the `/examples` directory, they include instructions on __how to run and test__.

## Contributing

1. Contributions to this project are more than welcomed!
    - Anything from improving docs, code cleanup to advanced functionality is greatly appreciated.
    - Before you start working on an ideea, please open an issue and describe in detail what you want to do and __why it's important__.
    - You will get an answer in max 12h depending on your timezone.
2. Fork the repo!
3. If you use [vagrant](https://www.vagrantup.com/) then simply clone the repo into a folder then issue `$ vagrant up`
    - if you don't use it, please consider learning it, it's easy to install and to get started with.
    - If you don't use it, then you have to:
         - install `rabbitmq-server` and enable `rabbitmq_management` plugin.
         - install node.js and all node packages required in development using `$ npm install`
         - For reference, see `./vagrant_boostrap.sh` for instructions on how to setup all dependencies on a fresh ubuntu 14.04 machine.
    - Run the tests to make sure you have a correct setup: `$ npm run test`
4. Create a new branch and implement your feature.
 - make sure you add tests for your feature. In the end __all tests have to pass__! To run test suite `$ npm run test`.
 - make sure test coverage does not decrease! Run `$ npm run coverage` to open a browser window with the coverage report.
 - make sure you document your code and that the generated code looks ok. Run `$ npm run doc` to re-generate the documentation.
 - make sure source code and test code are linted. Run `$ npm run lint`
 - submit a pull request with your code.
 - hit me up for a code review!
5. Have my kindest thanks for making this project better!


## Licence

(The MIT License)

Copyright (c) 2012 Alexandru Topliceanu (alexandru.topliceanu@gmail.com)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
