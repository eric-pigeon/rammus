module Chromiebara
  class Response
    TIMEOUT = 5

    def initialize
      @mutex = Mutex.new
      @cv = ConditionVariable.new
      @value = nil
    end

    def await
      @mutex.synchronize do
        # TODO better timeout
        @cv.wait(@mutex, TIMEOUT)
        raise 'TIMEDOUT' if @value.nil?
        @value
      end
    end

    def resolve(value)
      @mutex.synchronize do
        @value = value
        @cv.broadcast
      end
    end
  end
end
