module Rammus
  # @!visibility private
  #
  module EventEmitter
    # @!visibility private
    #
    EVENT_QUEUE = Queue.new
    # @!visibility private
    #
    EXECUTOR = Thread.new do
      loop do
        begin
          callback = EVENT_QUEUE.pop
          callback.call
        rescue => error
          # Normally would just set `#abort_on_exception = true` for this thread
          # but any test that is expecting an error to be raised in an event callback
          # would swallow the error but this thread would silently die
          Thread.main.raise error
        end
      end
    end

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

    def once(event, callable = nil, &block)
      callable ||= block
      fired = false
      emitter = self
      wrapper = ->(data) {
        emitter.remove_listener event, wrapper
        next if fired
        callable.call data
      }
      on event, wrapper
    end

    # @param [String] event
    # @param [Callable] callable
    #
    def remove_listener(event, callable)
      @_event_callbacks_mutex.synchronize do
        @_event_callbacks[event].delete callable
      end
    end

    def listener_count(event)
      @_event_callbacks_mutex.synchronize { @_event_callbacks[event].size }
    end

    # @param [String] event
    # @[aram [Hash] data
    #
    def emit(event, data = nil)
      @_event_callbacks_mutex.synchronize do
        @_event_callbacks[event].each do |callable|
          EVENT_QUEUE << -> { callable.call data }
        end
      end
    end
  end
end
