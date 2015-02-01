chai = require 'chai'
Q = require 'q'

util = require '../src/util'


describe 'util', ->

    describe '.backoff()', ->

        it 'should call given function repeatedly', (done) ->
            INFLECTION = 5
            END = 10
            counter = 0
            deferred = Q.defer()

            producer = ->
                counter += 1
                if counter is END then deferred.resolve()
                if counter in [INFLECTION, END] then return Q()
                return Q.reject()

            options =
                initialDelay: 10
                maxDelay: 1000
                startImmediately: true
            bf = util.backoff producer, options
            deferred.promise.then ->
                bf.reset()
            .then (-> done()), done

    describe '.pipe()', ->

        it 'should execute the steps in sequence '+
           'and pass on the modified context object', (done) ->
            context =
                first: true

            step1 = (context) ->
                context.second = true
                Q context

            step2 = (context) ->
                context.third = true
                Q context

            (util.pipe [step1, step2], context).then (after) ->
                expected =
                    first: true
                    second: true
                    third: true
                chai.assert.deepEqual after, context,
                    'should have sorted the data'
            .then (-> done()), done

        it 'should skip errors in sequence if ignoreErrors is true',(done)->
            context =
                first: true
            options =
                ignoreErrors: true

            step1 = (context) ->
                context.second = true
                Q context

            step2 = (context) ->
                throw new Error 'Some terrible error'
                context.third = true

            step3 = (context) ->
                context.fourth = true
                Q context

            (util.pipe [step1, step2, step3], context, options).then (after) ->
                expected =
                    first: true
                    second: true
                    fourth: true
                chai.assert.deepEqual after, context,
                    'should have ignored the error an move on with '+
                    'the next middleware step in the pip'
                chai.assert.isUndefined after.third,
                    'should not have pass through the errored step'
            .then (-> done()), done
