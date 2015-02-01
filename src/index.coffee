RabbitAmqpClient = require './RabbitAmqpClient'
RabbitHttpClient = require './RabbitHttpClient'


factory = (protocol = 'amqp') ->
    switch protocol
        when 'amqp' then RabbitAmqpClient
        when 'http' then RabbitHttpClient
        else
            throw new Error "Protocol #{protocol} not defined"


instances = {}

singleton = (protocol = 'amqp', params = {}) ->
    unless instances[protocol]?
        Class = factory protocol
        instances[protocol] = new Class params

    return instances[protocol]



exports.RabbitAmqpClient = RabbitAmqpClient
exports.RabbitHttpClient = RabbitHttpClient
exports.factory = factory
exports.singleton = singleton
