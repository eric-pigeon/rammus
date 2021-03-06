# frozen_string_literal: true

module Rammus
  RSpec.describe EventEmitter do
    let(:emitter) { TestEmitter.new }

    describe '#once' do
      xit 'only runs the callback once' do
        pending 'this does not really work since the queue might not be empty at the end'
        count = 0
        mutex = Mutex.new
        condition = ConditionVariable.new
        callback = ->(_) do
          mutex.synchronize do
            count += 1
            condition.broadcast
          end
        end
        emitter.once :test, callback

        mutex.synchronize do
          emitter.public_emit :test, nil
          condition.wait mutex
        end

        expect(count).to eq 1

        emitter.public_emit :test, nil

        expect(EventEmitter::EVENT_QUEUE.length).to eq 0

        expect(count).to eq 1
      end
    end
  end
end
