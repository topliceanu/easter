chai = require 'chai'

easter = require '../src/'


describe 'easter', ->

    describe '.factory()', ->

        it 'should throw for an unsupported protocol', ->
            chai.assert.throws ->
                easter.factory 'websockets'
            , Error, /Protocol websockets not defined/

    describe '.singleton()', ->

        it 'should cache the instance of a protocol client', ->
            amqpClient1 = easter.singleton 'amqp'
            amqpClient2 = easter.singleton 'amqp'
            chai.assert.equal amqpClient1, amqpClient2,
                'should return the same client instance'
            chai.assert.instanceOf amqpClient1, easter.RabbitAmqpClient,
                'should be an instance of amqp protocol client'

            amqpClient3 = easter.singleton 'http'
            amqpClient4 = easter.singleton 'http'
            chai.assert.equal amqpClient3, amqpClient4,
                'should return the same client instance'
            chai.assert.instanceOf amqpClient3, easter.RabbitHttpClient,
                'should be an instance of amqp protocol client'
