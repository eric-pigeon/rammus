module Chromiebara
  module EventEmitter
    EVENT_QUEUE = Queue.new
    EXECUTOR = Thread.new do
      loop do
        callback = EVENT_QUEUE.pop
        callback.call
      end
    end.abort_on_exception = true

    def initialize
      @_event_callbacks = Hash.new { |h, k| h[k] = [] }
      @_event_callbacks_mutex = Mutex.new
    end

    # @param [String] event
    # @param [Callable] callable
    #
    def on(event, callable = nil, &block)
      callable ||= block
      @_event_callbacks_mutex.synchronize do
        @_event_callbacks[event] << callable
      end
    end

    # @param [String] event
    # @param [Callable] callable
    #
    def remove_listener(event, callable)
      @_event_callbacks_mutex.synchronize do
        @_event_callbacks[event].delete callable
      end
    end

    private

      # @param [String] event
      # @[aram [Hash] data
      #
      def emit(event, data)
        @_event_callbacks_mutex.synchronize do
          @_event_callbacks[event].each do |callable|
            EVENT_QUEUE << -> { callable.call data }
          end
        end
      end
  end
end
