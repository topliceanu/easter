_ = require 'underscore'
chai = require 'chai'
Q = require 'q'

RabbitAmqpClient = require '../src/RabbitAmqpClient'
RabbitHttpClient = require '../src/RabbitHttpClient'


describe 'RabbitHttpClient', ->

    describe '.publish()', ->

        TEST_QUEUE = 'test-queue-8'

        before (done) ->
            # Create a new test queue.
            @httpClient = new RabbitHttpClient port: 15672
            @client = new RabbitAmqpClient
            (@client.queue TEST_QUEUE).then (-> done()), done

        it 'should publish a new message via http request', (done) ->
            Q().then =>
                @payload = {'some': 'message'}
                @httpClient.publish TEST_QUEUE, @payload
            .then =>
                deferred = Q.defer()
                @client.subscribe TEST_QUEUE, (error, data, ack) =>
                    ack()
                    if error? then return deferred.reject error
                    chai.assert.deepEqual data, @payload,
                        'should have published the message via REST Api'
                    deferred.resolve()
                deferred.promise
            .then (-> done()), done

    describe '.consume()', ->

        TEST_QUEUE = 'test-queue-9'

        before (done) ->
            # Create a new test queue.
            @httpClient = new RabbitHttpClient port: 15672
            @client = new RabbitAmqpClient
            (@client.queue TEST_QUEUE).then (-> done()), done

        it 'should read a message from a given queue', (done) ->
            Q().then =>
                @payload = {'some': 'other message'}
                @client.publish TEST_QUEUE, @payload
            .then ->
                Q.delay(100)
            .then =>
                @httpClient.consume TEST_QUEUE, count: 10
            .then (messages) =>
                chai.assert.lengthOf messages, 1, 'only one message on the queue'
                chai.assert.deepEqual messages[0], @payload,
                    'should read the messages previously inserted'
            .then =>
                # Attempt to consume an empty queue.
                @httpClient.consume TEST_QUEUE, count: 10
            .then (messages) ->
                chai.assert.isArray messages, 'should return array'
                chai.assert.lengthOf messages, 0, 'no messages found on queue'
            .then (-> done()), done

    describe '.subscribe()', ->

        TEST_QUEUE = 'test-queue-10'

        before ->
            # Create a new test queue.
            @httpClient = new RabbitHttpClient port: 15672
            @client = new RabbitAmqpClient

        it 'should continuously poll the queue for messages '+
           'but process them in order of arrival', (done) ->
            @timeout 5000
            NUM_MSG = 22

            Q().then =>
                @client.queue TEST_QUEUE
            .then =>
                Q.all _.map [1..NUM_MSG], (index) =>
                    @client.publish TEST_QUEUE, index
            .then =>
                count = 0
                deferred = Q.defer()
                @httpClient.subscribe TEST_QUEUE, (error, message, ack) ->
                    Q().then ->
                        # Introduce an artificial delay to simulate
                        # heavy worker processing.
                        Q.delay 100
                    .then ->
                        console.log 'info', 'received a message', message
                        ack()
                        count += 1
                        if count is NUM_MSG then deferred.resolve()
                        Q()
                deferred.promise
            .then (-> done()), done
