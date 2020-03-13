module Rammus
  # @!visibility private
  #
  class EventQueue < SimpleDelegator
    def initialize
      super Queue.new
      @_exectuor = Thread.new do
        loop do
          begin
            callback = self.pop
            callback.call
          rescue => error
            # Normally would just set `#abort_on_exception = true` for this thread
            # but any test that is expecting an error to be raised in an event callback
            # would swallow the error but this thread would silently die
            Thread.main.raise error
          end
        end
      end
    end

    # @param [String] session_id
    #
    # @return [Concurrent::Promises::ResolvableFuture<nil>]
    #
    def wait_for_events(session_id)
    end

    def self.wait_for_events(session_id)
      SESSION_EVENT_COUNTS_MUTEX.synchronize do
        return Promise.resolve(nil) if SESSION_EVENT_COUNTS[session_id].zero?

        SESSION_COUNT_PROMISES[session_id] || Promise.new do |resolve, _reject|
          SESSION_COUNT_PROMISES[session_id] = resolve
        end
      end
    end
    Event = Struct.new(:session_id, :callback, :data)
  end

  # @!visibility private
  #
  module EventEmitter
    # @!visibility private
    #
    Event = Struct.new(:session_id, :callback, :data)

    # @!visibility private
    #
    # EVENT_QUEUE = Queue.new
    # @!visibility private
    #
    # EXECUTOR = Thread.new do
    #   loop do
    #     begin
    #       callback = event_queue.pop
    #       callback.call
    #     rescue => error
    #       # Normally would just set `#abort_on_exception = true` for this thread
    #       # but any test that is expecting an error to be raised in an event callback
    #       # would swallow the error but this thread would silently die
    #       Thread.main.raise error
    #     end
    #   end
    # end

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
    # @param [Hash, Object] data
    #
    def emit(event, data = nil)
      @_event_callbacks_mutex.synchronize do
        @_event_callbacks[event].each do |callable|
          event_queue << -> { callable.call data }
        end
      end
    end
  end
end
