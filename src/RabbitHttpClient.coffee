_ = require 'underscore'
request = require 'request'
Q = require 'q'

Client = require './Client'
util = require './util'


class RabbitHttpClient extends Client
    ###
        Communicate with RabbitMQ server through the HTTP API.

        NOTICE All message consumed by the httpclient off a queue
        are immediately ACKed!
    ###

    defaultPublishOptions: {}

    defaultReadOptions:
        count: 1
        requeue: false
        encoding: 'auto'

    publish: (queueName, data, options = {}) ->
        ###
            Publishes a message to a RabbitMQ queue on the default
            exchange (amq.default) using the REST API.

            @param {String} queueName
            @param {Object} queueOpts
            @return {Object} Q.Promise resolving to a Queue instance.

            curl -i -u <user>:<pass> \
                 -H 'content-type:application/json' \
                 -d '{
                        "properties":<options>,
                        "routing_key":<queueName>,
                        "payload":<data>,
                        "payload_encoding":"string"
                     }' \
                 -XPOST http://rabbitmq/api/exchanges/%2f/amq.default/publish
        ###
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

    consume: (queueName, options = {}) ->
        ###
            Retrieves a message from a RabbitMQ endpoint and
            consume it at the same time (ie. send ACK).

            curl -i -u vibetrace:V2PBCZLa0dS2 \
                 -H 'content-type:application/json' \
                 -d '{
                        "count":1,
                        "requeue":false,
                        "encoding":"auto"
                     }' \
                 -XPOST http://rabbitmq/api/queues/%2f/<queueName>/get

            @param {String} queueName - name of the queue to subscribe to.
            @param {Object} options - list of options to read
            @return {Object} Q.Promise resolves to an Array<String> of messages.
        ###
        endpoint = "/api/queues/%2f/#{queueName}/get"
        body = _.extend {}, @defaultReadOptions, options
        (@call endpoint, body).then (messages) ->
            Q _(messages).chain().pluck('payload').map(JSON.parse).value()

    subscribe: (queueName, callback, options = {}) ->
        ###
            This method polls the queue endpoint and consumes data as soon as
            it appears.

            It implements a fibonacci polling mechanism to
            ensure efficient bandwidth consumption, ie. whenever a call to
            the queue returns empty results, it will wait that much longer
            before calling again. If the call returns data, it will fetch more
            data immediately after consumption.

            To implement the api of the native rabbitmq client, the callback
            executed for each message also receives the ack function which it
            will call whenever the message is consumed. This is fake as
            the message is already consumed by the time it reaches the callback.

            @param {String} queueName
            @param {Function} callback - whenever a new message is retrieved
                         this callback is executed. Signature:
                         function (error, message, ack) {..}
            @param {Object} options - extra params
            @param {Number} options.count - Number of messages to consume.
                                            Defaults to 10.
        ###
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

    call: (endpoint, body) ->
        ###
            Utility method to call an HTTP endpoint given
            @private
            @param {String} endpoint - http path&query string of the url to call
            @param {Object} body - http request body
            @return {Object} Q.promise
        ###
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
