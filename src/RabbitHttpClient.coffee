_ = require 'underscore'
request = require 'request'
Q = require 'q'

Client = require './Client'
util = require './util'



# Communicate with RabbitMQ server through the HTTP API which can be started
# by enabling the rabbitmq management plugin.
#
# @note All message consumed by the http client off a queue are immediately ACKed!
#
class RabbitHttpClient extends Client

    # Default message publishing options.
    defaultPublishOptions: {}

    # Default message consumption options.
    defaultReadOptions:
        # How many messages to consume with one request. By default it's 1.
        count: 1
        # Whether to re-enqueue the messages after consumption. By default it's false.
        requeue: false
        # Default encoding to use for message payloads.
        encoding: 'auto'

    # Constructs a rabbitmq client using the http protocol
    #
    # @param {Object} options
    # @option host {String} Ip of machine where rabbitmq server is installed. Defaults to 'localhost'.
    # @option port {Number} Port where the rabbitmq server is listening. Defaults to 15672 for http.
    # @option vhost {String} Rabbitmq virtual host. Defaults to '/'.
    # @option login {String} Username to login to the api. Defaults to 'guest'
    # @option password {String} Password to login to the api. Defaults to 'guest'
    #
    constructor: (options = {}) ->
        options?.port = 15672
        super options

    # Publishes a message to a RabbitMQ queue on the default
    # exchange (amq.default) using the REST API.

    # @param {String} queueName
    # @param {Object} queueOpts
    # @return {Object} Q.Promise resolving to a Queue instance.
    # @example
    #   curl -i -u <user>:<pass> \
    #        -H 'content-type:application/json' \
    #        -d '{
    #               "properties":<options>,
    #               "routing_key":<queueName>,
    #               "payload":<data>,
    #               "payload_encoding":"string"
    #            }' \
    #        -XPOST http://rabbitmq/api/exchanges/%2f/amq.default/publish
    #
    publish: (queueName, data, options = {}) ->
        endpoint = '/api/exchanges/%2f/amq.default/publish'
        body =
            properties: _.extend @defaultPublishOptions, options
            routing_key: queueName
            payload: JSON.stringify data
            payload_encoding: 'string'
        (@call endpoint, body).then (result) ->
            if result?.routed isnt true
                Q.reject new Error 'Message was not published'
            else
                Q()

    # Retrieves a message from a RabbitMQ endpoint and
    # consume it at the same time (ie. send ACK).
    #
    # @example
    #   curl -i -u vibetrace:V2PBCZLa0dS2 \
    #        -H 'content-type:application/json' \
    #        -d '{
    #               "count":1,
    #               "requeue":false,
    #               "encoding":"auto"
    #            }' \
    #        -XPOST http://rabbitmq/api/queues/%2f/<queueName>/get
    #
    # @param {String} queueName - name of the queue to subscribe to.
    # @param {Object} options - list of options to read
    # @option count {Boolean}  How many messages to consume with one request. By default it's 1.
    # @option requeue {Boolean} Whether to re-enqueue the messages after consumption. By default it's false.
    # @option encoding {String}  Default encoding to use for message payloads.
    # @return {Object} Q.Promise resolves to an Array<String> of messages.
    #
    consume: (queueName, options = {}) ->
        endpoint = "/api/queues/%2f/#{queueName}/get"
        body = _.extend {}, @defaultReadOptions, options
        (@call endpoint, body).then (messages) ->
            Q _(messages).chain().pluck('payload').map(JSON.parse).value()

    # This method polls the queue endpoint and consumes data as soon as
    # it appears.
    #
    # It implements a fibonacci polling mechanism to
    # ensure efficient bandwidth consumption, ie. whenever a call to
    # the queue returns empty results, it will wait that much longer
    # before calling again. If the call returns data, it will fetch more
    # data immediately after consumption.
    #
    # To implement the api of the native rabbitmq client, the callback
    # executed for each message also receives the ack function which it
    # will call whenever the message is consumed. This is fake as
    # the message is already consumed by the time it reaches the callback.
    #
    # @param queueName {String} The queue will be created if it does not exist.
    # @param callback {Function} whenever a new message is retrieved this callback is executed. Signature: function (error, message, ack) {..}
    # @param options {Object} extra params
    # @option count {Number} Number of messages to consume. Defaults to 10.
    #
    subscribe: (queueName, callback, options = {}) ->
        options.count ?= 10

        call = =>
            @log 'info', 'polling the rabbitmq queue', queueName
            (@consume queueName, count: options.count).then (messages) ->
                unless messages?.length > 0
                    return Q.reject new Error 'Nothing to consume'
                steps = _.map messages, (message) ->
                    return ->
                        deferred = Q.defer()
                        callback null, message, deferred.makeNodeResolver()
                        deferred.promise
                util.pipe steps, null, ignoreErrors: true

        util.backoff call,
            strategy: 'fibonacci'
            maxDelay: 1 * 60 * 1000
            startImmediately: true

    # Utility method to call an HTTP endpoint given
    #
    # @private
    # @param endpoint {String} Http path&query string of the url to call.
    # @param body {Object} Http request body.
    # @return {Q.promise} Resolves when the call is completed.
    #
    call: (endpoint, body) ->
        options =
            method: 'POST'
            url: "http://#{@options.host}:#{@options.port}#{endpoint}"
            auth:
                user: @options.login
                pass: @options.password
                sendImmediately: true
            header:
                'Content-type': 'application/json'
                'Accept': 'application/json'
            body: JSON.stringify body

        deferred = Q.defer()
        request options, (error, response, body) ->
            if error? then return deferred.reject error
            unless response.statusCode is 200
                return deferred.reject new Error body
            deferred.resolve JSON.parse body
        deferred.promise


# Public API.
module.exports = RabbitHttpClient
