require 'timeout'

module Chromiebara
  class Response
    def initialize
      @mutex = Mutex.new
      @cv = ConditionVariable.new
      @value = nil
    end

    def await(timeout = 2)
      deadline = current_time + timeout

      @mutex.synchronize do
        loop do
          return @value unless @value.nil?

          to_wait = deadline - current_time
          raise Timeout::Error, "Timed out waiting for response" if to_wait <= 0
          @cv.wait(@mutex, to_wait)
        end
      end
    end

    def resolve(value)
      @mutex.synchronize do
        @value = value
        @cv.broadcast
      end
    end

    private

      def current_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
  end
end
