#!/usr/bin/env bash

# Init.
apt-get update

# Install node.
NODE_VERSION=0.10.35
apt-get -y install g++ gcc make
wget http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.gz -O /tmp/nodejs.tar.gz
tar -xzvf /tmp/nodejs.tar.gz -C /home/vagrant
chown -R vagrant:vagrant /home/vagrant/node-v$NODE_VERSION
su - vagrant -c "/home/vagrant/node-v$NODE_VERSION/configure"
su - vagrant -c "cd /home/vagrant/node-v$NODE_VERSION; make"
su - vagrant -c "cd /home/vagrant/node-v$NODE_VERSION; sudo make install"

# Install node dependencies.
su - vagrant -c "cd /vagrant/; npm install"

# Install and configure RabbitMQ.
echo 'deb http://www.rabbitmq.com/debian/ testing main' | tee /etc/apt/sources.list.d/rabbitmq.list
wget -qO - http://www.rabbitmq.com/rabbitmq-signing-key-public.asc | apt-key add -
apt-get update
apt-get install -y rabbitmq-server
rabbitmq-plugins enable rabbitmq_management
