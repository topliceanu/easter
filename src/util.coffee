_ = require 'underscore'
backoff = require 'backoff'
Q = require 'q'


# This module implements a backoff mechanism when calling the given
# function in a recursive manner. Ie. the call to fn() is done repeteadly,
# whenever the promise returned is resolved the interval shrinks to a
# minimum low, whenever the promise is rejected the interval increases to a maximum high.
#
# @see https://github.com/MathieuTurcotte/node-backoff
# @param {Function} fn - a function that MUST return a promise.
# @param {Object} options
# @option strategy {String} One of 'fibonacci' or 'exponential'.
# @option randomisationFactor {Number} increasing call intervals can be made more variable using this option. Can be from [0, 1]. Defaults to 0
# @option initialDelay {Number} how much to wait in ms to get the first call going. Defaults to 100ms.
# @option maxDelay {Number} the maximum delay between calls.
# @option startImmediately {Boolean} whether or not to start the backoff process immediately. Defaults to false.
# @return {Object} instance of backoff.Backoff class.
#
exports.backoff = (fn, options = {}) ->
    unless options.strategy in ['fibonacci', 'exponential']
        options.strategy = 'fibonacci'
    unless 0 < options.randomisationFactor < 1
        options.randomisationFactor = 0
    unless (_.isNumber options.initialDelay) and options.initialDelay > 0
        options.initialDelay = 10
    unless (_.isNumber options.maxDelay) and 0 < options.initialDelay < options.maxDelay
        options.maxDelay = 1 * 60 * 1000 # 1 minute in ms.
    unless (_.isBoolean options.startImmediately)
        options.startImmediately = false

    instance = (backoff[options.strategy] options)
    instance.on 'ready', ->
        fn().then ->
            instance.reset()
        .finally ->
            instance.backoff()

    if options.startImmediately is true then instance.backoff()
    return instance


# Utility method that executed all steps given and applies the context
# object resulted form the previous step to the next step.
#
# @param steps {Array<Function>} A list of functions, each one receives the `context` object as param, modify it, then pass it onto the next step.
# @param context {Object} An object which passes through the step pipe.
# @param {Object} options
# @option ignoreErrors {Boolean} If this flag is true, if a step in the pipeline errors, the next step will execute.
# @note Normal behaviour is to stop to the pipe.
#
exports.pipe = (steps, context = {}, options = {}) ->
    options.ignoreErrors ?= false
    steps.reduce (soFar, step) ->
        if options.ignoreErrors is true
            soFar = soFar.fail (error) ->
                Q context
        return soFar.then step
    , Q context
