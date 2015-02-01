RabbitAmqpClient = require './RabbitAmqpClient'
RabbitHttpClient = require './RabbitHttpClient'


# Factory method produces the class responsible for interacting with rabbitmq
# given the specified protocol.
#
# @param protocol {String} Either 'amqp' or 'http'.
# @throw Error when the protocol is not supported.
# @return {easter.Client} Implementation of Client class.
#
factory = (protocol = 'amqp') ->
    switch protocol
        when 'amqp' then RabbitAmqpClient
        when 'http' then RabbitHttpClient
        else
            throw new Error "Protocol #{protocol} not defined"


instances = {}

# Singleton utility method to produce the same instance for a given
# transport every time.
#
# @note Only the instance created with the first set of params will be cached.
# @param protocol {String} Either 'amqp' or 'http'.
# @param {Object} params
# @option host {String} Ip of machine where rabbitmq server is installed. Defaults to 'localhost'.
# @option port {Number} Port where the rabbitmq server is listening. Defaults to 5672 for amqp.
# @option vhost {String} Rabbitmq virtual host. Defaults to '/'.
# @option login {String} Username to login to the api. Defaults to 'guest'
# @option password {String} Password to login to the api. Defaults to 'guest'
# @return {easter.Client} Instance of client specific for the given protocol.
#
singleton = (protocol = 'amqp', params = {}) ->
    unless instances[protocol]?
        Class = factory protocol
        instances[protocol] = new Class params

    return instances[protocol]


# Public API.
exports.RabbitAmqpClient = RabbitAmqpClient
exports.RabbitHttpClient = RabbitHttpClient
exports.factory = factory
exports.singleton = singleton
