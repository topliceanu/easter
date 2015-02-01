/**
 * Simple example of using easter. The library exposes two implementations
 * with the same interface, one for http and one for amqp protocols.
 *
 * This example shows how to publish a message using the HTTP client and how
 * to subscribe for it using the AMQP protocol.
 *
 * Note that when working with distributed queues, consuming messages is tricky.
 * When a message is consumed, it is removed from rabbitmq server and thus is
 * no longer available. However if you consume the message too early and an
 * error occurs in it's processing after it was consumed, you miss a chance
 * that another worker could get that message at a later time and process it
 * correctly. To allow for this behaviour, you must make sure that if a message
 * is retrieved multiple times it does not render the application state
 * inconsistent.
 *
 * Usage:
 * $ node basic-example.js
 * > Publishing message on the queue
 * > Consumed message from queue
 */

easter = require('easter');


amqpClient = easter.singleton('amqp', {host: 'localhost', port: 5672});
httpClient = easter.singleton('http', {host: 'localhost', port: 15672});

amqpClient.subscribe('my-test-queue', function (error, message, consume) {
    consume();
    if(error) {
        return console.log('Failed to connect/fetch message from queue', error);
    }
    console.log('Consumed message from queue');
});

console.log('Publishing message on the queue');
httpClient.publish('my-test-queue', 'hello easter rabbitmq');
