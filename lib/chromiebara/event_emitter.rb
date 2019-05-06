module Chromiebara
  module EventEmitter
    def initialize
      @_event_callbacks = Hash.new { |h, k| h[k] = [] }
      @_event_callbacks_mutex = Mutex.new
    end

    # @param [String] event
    # @param [Callable] callable
    #
    def on(event, callable)
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
          @_event_callbacks[event].each { |callable| callable.call data }
        end
      end
  end
end
