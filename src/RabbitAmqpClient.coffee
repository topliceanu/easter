_ = require 'underscore'
amqp = require 'amqp'
Q = require 'q'

Client = require './Client'
util = require './util'


class RabbitAmqpClient extends Client

    # Delivery modes for rabbitmq messages.
    DELIVERY_MODES =
        TRANSIENT: 1
        PERSISTENT: 2

    defaultQueueOptions:
        # Server will attempt to create the queue if it does not exist yet.
        passive: false
        # Makes the queue to self-destruct when all consumers have finished
        # with it, ie. close their channel to the queue.
        autoDelete: false
        # Durable queues are persistent, ie support persistent messages.
        # All non-persistent messages will be lost in case of a reboot.
        durable: true
        # Exclusive queues can be consumed only from the current location.
        exclusive: false
        # Allow the queue to be deleted even if the client does not know it's
        # options. By default this is not permitted.
        noDeclare: false

    defaultPublishOptions:
        # Makes all the messages published by the client persistent.
        deliveryMode: DELIVERY_MODES.PERSISTENT

    defaultSubscribeOptions:
        # Makes Rabbit only send a new message to the consumer when the ACK
        # from the last one was received. To send ACK, use queue#shift()
        ack: true
        # Number of messages allows to wait in the worker's buffer at a time.
        prefetchCount: 1

    # Q.Promise resolving to an instance of amqp.Connection.
    connection: null

    # A hash of promises to queues created by the current client.
    queues: {}

    constructor: (options) ->
        super options
        @connect()

    connect: ->
        ###
            Connects to a RabbitMQ server.
            @return {Object} Q.Promise resolves to amqp.Connection.
        ###
        deferred = Q.defer()
        connection = amqp.createConnection @options

        connection.on 'ready', =>
            @log 'info', '[AMQP Client] Connection established', @options
            deferred.resolve connection

        connection.on 'error', (error) =>
            @log 'error', '[AMQP Client] Connection failed!',
                error, @options
            deferred.reject error

        @connection = deferred.promise
        @connection

    disconnect: ->
        ###
            Connects to a RabbitMQ server.
            @return {Object} Q.Promise resolves when the connection is closed.
        ###
        @connection.then (connection) ->
            connection.destroy()

    queue: (queueName, queueOpts = {}) ->
        ###
            Method defines/creates a queue. Calls to RabbitMQ are
            `idempotent` so the queue will not be created twice. However
            we are caching the queue promise to prevent unnecessary requests.

            @param {String} queueName
            @param {Object} queueOpts
            @return {Object} Q.Promise resolving to a Queue instance.
        ###
        unless @queues[queueName]?
            deferred = Q.defer()
            options = _.extend @defaultQueueOptions, queueOpts
            @connection.then (connection) ->
                connection.queue queueName, options, (queue) ->
                    deferred.resolve queue
            @queues[queueName] = deferred.promise

        @queues[queueName]

    publish: (queueName, data, options = {}) ->
        ###
            Publish a message on a rabbit queue.

            Note! that even though the publish action is done on the
            connection a link to a queue must be performed or ensured.

            @param {String} queueName - name of the queue to publish to.
            @param {Mixed} data - will go through JSON.stringify serialization.
            @param {Object} options
            @return {Object} Q.Promise
        ###
        options = _.extend @defaultPublishOptions, options
        json = JSON.stringify data
        @connection.then (connection) =>
            (@queue queueName).then (queue) ->
                connection.publish queueName, json, options

    subscribe: (queueName, callback, options = {}) ->
        ###
            Subscribe to a rabbitmq queue. Whenever a message is received, the
            callback is executed with that message.

            Local function is used by event callbacks to
            trigger the ACK for the queue. If an error is
            passed, it's logged but the message is considered
            to be consumed.

            @param {String} queueName - name of the queue to subscribe to.
            @param {Function} callback - continuation, signature is:
                                         `function (error, data, ack) {}`
                                         NOTE! Call ack() to consume the
                                         message, or it will get republished!
            @param {Object} options
        ###
        options = _.extend @defaultSubscribeOptions, options
        (@queue queueName).then (queue) ->
            queue.subscribe options, (message, headers, meta) ->
                ack = ->
                    queue.shift()

                try
                    data = JSON.parse message.data.toString 'UTF-8'
                    callback null, data, ack
                catch exception
                    callback exception, null, ack
        , (error) ->
            callback error, null, _.noop


# Public API.
module.exports = RabbitAmqpClient
