require 'timeout'

module Chromiebara
  class Promise
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
        acc.then{ puts "first then #{promise}"; promise }
          .then { |result| puts "second then #{result}"; results.push result }
      end

      merged.then { results }
    end

    def self.create
      promise = new
      [promise, promise.method(:resolve), promise.method(:reject)]
    end

    def initialize(on_fulfill = nil, on_reject = nil, &block)
      @_state = PENDING
      @_mutex = Mutex.new
      @_condition_variable = ConditionVariable.new
      @_value = nil
      @_on_resolve = on_fulfill
      @_on_reject = on_reject
      @_next_resolve = nil
      @_next_reject = nil

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
          when FULFILLED
            return @_value
          when REJECTED
            if @_on_reject
              return @_value
            else
              raise UnhandledRejection
            end
          end

          to_wait = deadline - current_time
          raise Timeout::Error, "Timed out waiting for response" if to_wait <= 0
          @_condition_variable.wait @_mutex, to_wait
        end
      end
    end

    def then(on_fulfill = nil, on_reject = nil, &block)
      on_fulfill ||= block

      next_promise = Promise.new on_fulfill, on_reject do |resolve, reject|
        @_next_resolve = resolve
        @_next_reject = reject
      end

      @_mutex.synchronize do
        case @_state
        when FULFILLED
          @_next_resolve.(@_value)
        when REJECTED
          @_next_reject.(@_value)
        end
      end

      next_promise
    end

    def catch(on_reject = nil, &block)
      on_reject ||= block

      self.then nil, on_reject
    end

    private

      def fulfilled?
        @_state != PENDING
      end

      PENDING = :pending
      FULFILLED = :fulfilled
      REJECTED = :rejected

      def resolve(value)
        @_mutex.synchronize do
          next if @_state != PENDING

          begin
            @_value = if @_on_resolve
                        @_on_resolve.call value
                      else
                        value
                      end
            @_state = FULFILLED
            @_condition_variable.broadcast
            @_next_resolve.(@_value) if @_next_resolve
        rescue => error
          @_state = REJECTED
          @_value = error
          @_condition_variable.broadcast
          @_next_reject.(@_value) if @_next_reject
          end
        end
      end

      def reject(value)
        @_mutex.synchronize do
          next if @_state != PENDING

          @_state = REJECTED
          @_value = if @_on_reject
                      @_on_reject.call value
                    else
                      value
                    end
          @_condition_variable.broadcast
          @_next_reject.(@_value) if @_next_reject
        end
      end

      def current_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
  end
end
