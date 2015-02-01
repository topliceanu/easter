_ = require 'underscore'


# Base class for Rabbitmq client implementations.
# Acts as an abstract class documenting the api for all implementations.
#
# @abstract This class should not be instantiated directly.
#
class Client

    # {Object} holding options for the specific rabbitmq connection.
    options: {}

    # Builds an client for rabbitmq server. All available options are detailed
    # here, but one should only pass only the needed options for the specific
    # implementations.
    #
    # @param {Object} options
    # @option host {String} Ip of machine where rabbitmq server is installed. Defaults to 'localhost'.
    # @option port {Number} Port where the rabbitmq server is listening. Defaults to 5672 for amqp.
    # @option vhost {String} Rabbitmq virtual host. Defaults to '/'.
    # @option login {String} Username to login to the api. Defaults to 'guest'
    # @option password {String} Password to login to the api. Defaults to 'guest'
    #
    constructor: (options = {}) ->
        defaults =
            host: 'localhost'
            port: 5672
            vhost: '/'
            login: 'guest'
            password: 'guest'
        @options = _.extend {}, defaults, options


    # Publishes a message to the specified queue.
    #
    # @abstract
    # @param queueName {String} The queue will be created if it does not exist.
    # @param data {Mixed} Message payload is passed through JSON.stringify.
    # @param options {Object} Options specific to the protocol implementation.
    # @return {Q.Promise} Resolves when the message is published.
    #
    publish: (queueName, data, options = {}) ->

    # Subscribes to a queue. Whenever a new message is available the
    # provided callback is executed with that message.
    # Make sure you ack() to consume the message.
    #
    # @abstract
    # @param queueName {String} The queue will be created if it does not exist.
    # @param callback {Function} function (error, message, ack) {...}
    # @param options {Object} Options specific to the protocol implementation.
    #
    subscribe: (queueName, callback, options = {}) ->

    # Log method allows users to hook custom logging infrastructure to easter.
    #
    # @param level {String} Can be anything, usually info, warn, debug, error.
    # @param message {String} Actuall log message.
    # @param context {Array<Object>} various objects relevant to message.
    log: (level, message, context...) ->
        console.log level, message, context...


# Public API.
module.exports = Client
