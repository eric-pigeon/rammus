module Chromiebara
  class Promise
    class UnhandledRejection < StandardError; end

    module Await
      def await(promise, timeout = 2)
        promise.await timeout
      end
    end

    def initialize(on_fulfill = nil, on_reject = nil, &block)
      @_state = :pending
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
          when :fulfilled
            return @_value
          when :rejected
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
        when :fulfilled
          @_next_resolve.(@_value)
        when :rejected
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

      def resolve(value)
        @_mutex.synchronize do
          next if @_state != :pending

          @_state = :fulfilled
          @_value = if @_on_resolve
                      @_on_resolve.call value
                    else
                      value
                    end
          @_condition_variable.broadcast
          @_next_resolve.(@_value) if @_next_resolve
        end
      end

      def reject(value)
        @_mutex.synchronize do
          next if @_state != :pending

          @_state = :rejected
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
