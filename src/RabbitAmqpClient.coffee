_ = require 'underscore'
amqp = require 'amqp'
Q = require 'q'

Client = require './Client'
util = require './util'


# Client implementation for the AMQP protocol.
#
class RabbitAmqpClient extends Client

    # Delivery modes for rabbitmq messages.
    DELIVERY_MODES =
        TRANSIENT: 1
        PERSISTENT: 2

    # Queue default options.
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

    # Publishing default options.
    defaultPublishOptions:
        # Makes all the messages published by the client persistent.
        deliveryMode: DELIVERY_MODES.PERSISTENT

    # Subscribe default options
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

    # Creates a new client for rabbitmq communicating through AMQP protocol.
    # @param {Object} options
    # @option host {String} Ip of machine where rabbitmq server is installed. Defaults to 'localhost'.
    # @option port {Number} Port where the rabbitmq server is listening. Defaults to 5672 for amqp.
    # @option vhost {String} Rabbitmq virtual host. Defaults to '/'.
    #
    constructor: (options) ->
        super options
        @connect()

    # Connects to a RabbitMQ server through AMQP.
    #
    # @return {Q.Promise} Resolves to amqp.Connection.
    #
    connect: ->
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

    # Connects to a RabbitMQ server.
    #
    # @return {Q.Promise} Resolves when the connection is closed.
    #
    disconnect: ->
        @connection.then (connection) ->
            connection.destroy()

    # Method defines/creates a queue. Calls to RabbitMQ are
    # `idempotent` so the queue will not be created twice. However
    # we are caching the queue promise to prevent unnecessary requests.
    #
    # @param queueName {String} The queue will be created if it does not exist.
    # @param queueOpts {Object} queue specific options.
    # @option passive {Boolean} Server will attempt to create the queue if it does not exist yet. Defaults to false.
    # @option autoDelete {Boolean} Makes the queue to self-destruct when all consumers have finished with it, ie. close their channel to the queue. Defaults to false.
    # @option durable {Boolean} Durable queues are persistent, ie support persistent messages. All non-persistent messages will be lost in case of a reboot. Defaults to true.
    # @option exclusive {Boolean} Exclusive queues can be consumed only from the current location. Defaults to false.
    # @option noDeclare {Boolean} Allow the queue to be deleted even if the client does not know it's options. By default this is not permitted. Defaults to false.
    # @return {Q.Promise} resolving to a Queue instance.
    #
    queue: (queueName, queueOpts = {}) ->
        unless @queues[queueName]?
            deferred = Q.defer()
            options = _.extend @defaultQueueOptions, queueOpts
            @connection.then (connection) ->
                connection.queue queueName, options, (queue) ->
                    deferred.resolve queue
            @queues[queueName] = deferred.promise

        @queues[queueName]

    # Publish a message on a rabbit queue.
    #
    # @note Even though the publish action is done on the connection a link to a queue must be performed or ensured.
    #
    # @param queueName {String} Name of the queue to publish to.
    # @param data {Object} Will go through JSON.stringify serialization.
    # @param options {Object} Options specific to the published message.
    # @option deliveryMode {Boolean} DELIVERY_MODES.PERSISTENT Makes all the messages published by the client persistent. Defaults to 1.
    # @return {Q.Promise} Resolves when the message has been published.
    #
    publish: (queueName, data, options = {}) ->
        options = _.extend @defaultPublishOptions, options
        json = JSON.stringify data
        @connection.then (connection) =>
            (@queue queueName).then (queue) ->
                connection.publish queueName, json, options

    # Subscribe to a rabbitmq queue. Whenever a message is received, the
    # callback is executed with that message.
    #
    # Local function is used by event callbacks to
    # trigger the ACK for the queue. If an error is
    # passed, it's logged but the message is considered
    # to be consumed.
    #
    # @note Call ack() to consume the message, or it will get republished!
    # @param queueName {String} name of the queue to subscribe to.
    # @param callback {Function} continuation, signature is `function (error, data, ack) {}`
    # @param options {Object} Options specific to the messages consumed.
    # @option ack {Boolean} Makes Rabbit only send a new message to the consumer when the ACK from the last one was received. To send ACK, use queue#shift(). Defaults to true.
    # @option prefetchCount {Boolean} Number of messages allows to wait in the worker's buffer at a time. Defaults to 1.
    #
    subscribe: (queueName, callback, options = {}) ->
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
