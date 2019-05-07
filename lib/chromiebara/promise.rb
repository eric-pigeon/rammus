module Chromiebara
  class Promise
    def initialize
      @_mutex = Mutex.new
      @_condition_variable = ConditionVariable.new
      @_value = nil
    end

    def await(timeout = 2)
      deadline = current_time + timeout

      @_mutex.synchronize do
        loop do
          return @_value unless @_value.nil?

          to_wait = deadline - current_time
          raise Timeout::Error, "Timed out waiting for response" if to_wait <= 0
          @_condition_variable.wait @_mutex, to_wait
        end
      end
    end

    def resolve(value)
      @_mutex.synchronize do
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
