_ = require 'underscore'


class Client
    ###
        @abstract
        Abstract class determining the api of all queue providers.
    ###

    options: {}

    constructor: (options = {}) ->
        ###
            Builds an http client for the rabbitmq management plugin rest api.
            @param {Object} options
            @option host {String} ip of machine where rabbitmq is installed. Defaults to 'localhost'.
            @option port {Number} port where the rabbitmq server is listening. Defaults to 5672.
            @option vhost {String} rabbitmq virtual host. Defaults to '/'.
            @option login {String} username to login to the api. Defaults to 'guest'
            @option password {String} password to login to the api. Defaults to 'guest'
        ###
        defaults =
            host: 'localhost'
            port: 5672
            vhost: '/'
            login: 'guest'
            password: 'guest'
        @options = _.extend {}, defaults, options

    publish: (queueName, data, options = {}) ->
        ###
            Publishes a message to the queue provider.
            @abstract
            @param {String} queueName
            @params {Mixed} data - this is passed through JSON.stringify.
            @return {Object} Q.Promise resolves when the message is published.
        ###

    subscribe: (queueName, callback, options = {}) ->
        ###
            Subscribes to a queue. Whenever a new message is consumed the
            provided callback is used.
            @abstract
            @param {String} queueName
            @param {Function} callback - function (error, message, ack) {...}
            @param {Object} options
        ###

    log: (level, message, context...) ->
        console.log level, message, context...


# Public API.
module.exports = Client
