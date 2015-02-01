_ = require 'underscore'
assert = (require 'chai').assert
Q = require 'q'

RabbitAmqpClient = require '../src/RabbitAmqpClient'


describe 'RabbitAmqpClient', ->

    describe 'Client', ->

        it '.connect() should connect to RabbitMQ server', (done) ->
            client = new RabbitAmqpClient
            client.connection.then (connection) ->
                assert.ok connection?, 'connection established'
            .then (-> done()), done

        it '.disconnect() should disconect from rabbitmq', (done) ->
            client = new RabbitAmqpClient
            client.connection.then ->
                client.disconnect()
            .then (-> done()), done

        it '.queue() should create a new queue given the options', (done) ->
            client = new RabbitAmqpClient

            (client.queue 'test-queue-0').then (queue) ->
                assert.ok queue?, 'should produce a queue'
                assert.isDefined client.queues['test-queue-0'],
                    'should have stored the queue promise'
                done()

        it '.publish()/subscribe() should publish then read a message', (done)->
            client = new RabbitAmqpClient

            data = test: Date.now()
            client.publish 'test-queue-1', data

            client.subscribe 'test-queue-1', (error, receivedData, ack) ->
                ack()
                if error? then done error
                assert.deepEqual receivedData, data
                done()

        it 'should work like a job queue with round robin', (done) ->
            ###
                Ie. it should dispatch messages to workers one at a time.
                This test sends 4 messages on the queue, and only one worker
                is available, he, should catch all of them.
            ###
            client = new RabbitAmqpClient

            messages = ("#{i}-#{Date.now()}" for i in [1..5])
            for message in messages
                client.publish 'test-queue-2', message

            client.subscribe 'test-queue-2', (error, message, ack) ->
                ack()
                if error? then done error
                assert.ok message in messages,
                    'one of the messages has arrived'

                # Remove the message from the buffer.
                messages = _.without messages, message
                done() if messages.length is 0

        it 'should work when a client publishes '+
           'messages on multiple queues', (done) ->
            listener = new RabbitAmqpClient

            count = 0
            message1 = "111-#{Date.now()}"
            message2 = "222-#{Date.now()}"

            listener.subscribe 'test-queue-3', (error, message, ack) ->
                ack()
                if error? then done error
                assert.equal message1, message, 'should receive the correct message'
                done() if ++count is 2

            listener.subscribe 'test-queue-4', (error, message, ack) ->
                ack()
                if error? then done error
                assert.equal message2, message, 'should receive the correct message'
                done() if ++count is 2

            emitter = new RabbitAmqpClient
            emitter.publish 'test-queue-3', message1
            emitter.publish 'test-queue-4', message2

        it 'instances are both publishers and subscribers', (done) ->
            client1 = new RabbitAmqpClient
            client2 = new RabbitAmqpClient

            data = test: Date.now()
            client1.publish 'test-queue-5', data

            client2.subscribe 'test-queue-5', (error, receivedData, ack) ->
                ack()
                if error? then done error
                assert.deepEqual receivedData, data
                done()

        xit 'should resend the message if ack is '+
           'not received by the first worker', (done) ->
            client1 = new RabbitAmqpClient
            client2 = new RabbitAmqpClient
            client3 = new RabbitAmqpClient

            data = test: Date.now()
            client1.publish 'test-queue-6', data

            client2.subscribe 'test-queue-6', (err, receivedData, ack) ->
                # NOTE: this client fails to call ack()
                if err? then done err
                assert.deepEqual data, receivedData,
                    'should receive the payload'

            client3.subscribe 'test-queue-6', (err, receivedData, ack) ->
                ack()
                if err? then done err
                assert.deepEqual data, receivedData,
                    'should receive the payload'
                done()

        it 'should not send ack immediately on event receive', (done) ->
            emitter = new RabbitAmqpClient
            subscriber = new RabbitAmqpClient
            otherSubscriber = new RabbitAmqpClient

            messageTaken = null

            subscriber.subscribe 'test-queue-7', (err, receivedData, ack) ->
                messageTaken = '1'
                if err?
                    ack()
                    return done err
                heavyDutyWork = ->
                    ack()
                    if messageTaken isnt '1'
                        return done Error 'Message taken by another worker'
                    done()
                setTimeout heavyDutyWork, 1000

            otherSubscriber.subscribe 'test-queue-7', (err, receivedData, ack)->
                messageTaken = '2'
                if err?
                    ack()
                    return done err
                heavyDutyWork = ->
                    ack()
                    if messageTaken isnt '2'
                        return done Error 'Message taken by another worker'
                    done()
                setTimeout heavyDutyWork, 1000

            emitter.publish 'test-queue-7', {data: true}
