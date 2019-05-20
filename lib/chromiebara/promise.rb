require 'timeout'

module Chromiebara
  class Promise
    EXECUTOR = Concurrent.global_io_executor
    class UnhandledRejection < StandardError; end

    module Await
      def await(promise, timeout = 2)
        promise.await timeout
      end
    end

    def self.resolve(value)
      Promise.new { |resolve| resolve.(value) }
    end

    def self.reject(value)
      Promise.new { |_, reject| reject.(value) }
    end

    def self.all(*promises)
      results = []

      merged = promises.reduce(Promise.resolve(nil)) do |acc, promise|
        acc.then{ promise }.then { |result| results.push result }
      end

      merged.then { results }
    end

    def self.create
      promise = new
      [promise, promise.method(:resolve), promise.method(:reject)]
    end

    def initialize(&block)
      @_state = PENDING
      @_mutex = Mutex.new
      @_condition_variable = ConditionVariable.new
      @_value = nil
      @_subscribers = []

      if block_given?
        begin
          yield method(:resolve), method(:reject)
        rescue => error
          reject error
        end
      end
    end

    def await(timeout = 2)
      deadline = current_time + timeout

      @_mutex.synchronize do
        loop do
          case @_state
          when RESOLVED
            return @_value
          when REJECTED
            raise UnhandledRejection.new @_value
          end

          to_wait = deadline - current_time

          raise Timeout::Error, "Timed out waiting for response after #{timeout}" if to_wait <= 0
          @_condition_variable.wait @_mutex, to_wait
        end
      end
    end

    def then(on_resolve = nil, on_reject = nil, &block)
      on_resolve ||= block

      subscriber = Subscriber.new(
        owner: self,
        promise: Promise.new,
        resolved: on_resolve,
        rejected: on_reject
      )

      @_mutex.synchronize do
        case @_state
        when PENDING
          @_subscribers << subscriber
        else
          subscriber.notify @_state, @_value
        end
      end

      subscriber.promise
    end

    def catch(on_reject = nil, &block)
      on_reject ||= block

      self.then nil, on_reject
    end

    private

      PENDING = :pending
      RESOLVED = :resolved
      REJECTED = :rejected

      class Subscriber
        attr_reader :owner, :promise, :resolved, :rejected

        def initialize(owner:, promise:, resolved:, rejected:)
          @owner = owner; @promise = promise; @resolved = resolved; @rejected = rejected
        end

        def notify(state, value)
          EXECUTOR.post(state, value) do |state, value|
            value =
              begin
                case state
                when RESOLVED
                  resolved.nil? ? value : resolved.(value)
                when REJECTED
                  if rejected.nil?
                    promise.send(:reject, value)
                    return
                  else
                    rejected.(value)
                  end
                end

              rescue => error
                promise.send(:reject, error)
              end

              promise.send(:resolve, value)
          end
        end
      end

      def resolve(value)
        chain = @_mutex.synchronize do
          next if @_state != PENDING

          if value.is_a? Promise
            true
          else
            @_value = value
            @_state = RESOLVED
            @_condition_variable.broadcast
            publish
            false
          end
        end
        # if the value is a fulfilled promise #then will cause this promise's
        # resolve to call and fail to aquire the mutex.
        value.then method(:resolve), method(:reject) if chain
      end

      def reject(value)
        @_mutex.synchronize do
          next if @_state != PENDING

          @_state = REJECTED
          @_value = value
          @_condition_variable.broadcast
          publish
        end
      end

      def publish
        @_subscribers.each { |subscriber| subscriber.notify @_state, @_value }
        @_subscribers.clear
      end

      def current_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
  end
end
