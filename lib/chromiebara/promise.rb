module Chromiebara
  class Promise
    def initialize
      @_fulfilled = false
      @_mutex = Mutex.new
      @_condition_variable = ConditionVariable.new
      @_value = nil
    end

    def await(timeout = 2)
      deadline = current_time + timeout

      @_mutex.synchronize do
        loop do
          return @_value if @_fulfilled

          to_wait = deadline - current_time
          raise Timeout::Error, "Timed out waiting for response" if to_wait <= 0
          @_condition_variable.wait @_mutex, to_wait
        end
      end
    end

    def then(on_fulfill = nil, on_reject = nil, &block)
      on_fulfill ||= block

      next_promise = self.class.new

      case state
      when :fulfilled
        defer { next_promise.promise_fulfilled(value, on_fulfill) }
      when :rejected
        defer { next_promise.promise_rejected(reason, on_reject) }
      else
        next_promise.source = self
        subscribe(next_promise, on_fulfill, on_reject)
      end

      next_promise
    end

    def resolve(value)
      @_mutex.synchronize do
        @_fulfilled = true
        @_value = value
        @_condition_variable.broadcast
      end
    end

    def reject(value)
      raise 'TODO'
      # TODO
    end

    private

      def current_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
  end
end
