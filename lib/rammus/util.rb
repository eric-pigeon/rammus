module Rammus
  # @!visibility private
  #
  module Util
    def self.evaluation_string(function_string, *args)
      "(#{function_string})(#{args.map(&:to_json).join(',')})"
    end

    # [Protocol.Runtime.RemoteObject] remote_object
    #
    def self.value_from_remote_object(remote_object)
      raise "Cannot extract value when objectId is given" if remote_object["objectId"]
      if remote_object["unserializableValue"]
        if remote_object["type"] == 'bigint'
          return remote_object["unserializableValue"].gsub("n", "").to_i
        end
        case remote_object["unserializableValue"]
        when '-0'
          return -0
        when 'NaN'
          return Float::NAN
        when 'Infinity'
          return Float::INFINITY
        when '-Infinity'
          return -Float::INFINITY
        else
          raise "Unsupported unserializable value #{remote_object["unserializableValue"]}"
        end
      end
      # return "undefined" if remote_object["type"] == "undefined"
      return remote_object["value"]
    end

    EventListener = Struct.new(:emitter, :event_name, :handler)

    def self.add_event_listener(emitter, event_name, handler = nil, &block)
      handler ||= block
      emitter.on event_name, handler
      EventListener.new emitter, event_name, handler
    end

    def self.remove_event_listeners(listeners)
      listeners.each do |listener|
        listener.emitter.remove_listener listener.event_name, listener.handler
      end
    end

    # @param {!Protocol.Runtime.ExceptionDetails} exceptionDetails
    # @return {string}
    #
    def self.get_exception_message(exception_details)
      if exception_details["exception"]
        return exception_details.dig("exception", "description") || exception_details.dig("exception", "value")
      end
      message = exception_details["text"]
      if exception_details["stackTrace"]
        exception_details["stackTrace"]["callFrames"].each do |call_frame|
          location = "#{call_frame["url"]}:#{call_frame["lineNumber"]}:#{call_frame["columnNumber"]}"
          function_name = call_frame.fetch "functionName", "<anonymous>"
          message += "\n    at #{function_name} (#{location})"
        end
      end
      message
    end

    # @param {!Puppeteer.CDPSession} client
    # @param {!Protocol.Runtime.RemoteObject} remote_object
    #
    def self.release_object(client, remote_object)
      return if remote_object["objectId"].nil?

      client.command(Protocol::Runtime.release_object object_id: remote_object["objectId"]).rescue do |error|
        # Exceptions might happen in case of a page been navigated or closed.
        # Swallow these since they are harmless and we don't leak anything in this case.
        debug_error error
      end.value!
    end

    # TODO document overload
    #
    # @param [EventEmitter] emitter
    # @param [String,Symbol] event_name
    # @param [Integer] timeout
    # @param [#call:Boolean] predicate
    #
    # @return [Concurrent::Promises::Future]
    #
    def self.wait_for_event(emitter, event_name, timeout = nil, abort_promise = nil, predicate = nil, &block)
      predicate ||= block
      event_timeout = nil

      future = Concurrent::Promises.resolvable_future

      listener = Util.add_event_listener(emitter, event_name) do |event|
        next unless predicate.(event)

        future.fulfill event
      end
      if timeout
        event_timeout = Concurrent::ScheduledTask.execute(timeout) do
          future.reject(Timeout::Error.new("Timeout exceeded while waiting for event"))
        end
      end
      cleanup = -> do
        Util.remove_event_listeners [listener]
        event_timeout.cancel
      end
      result =
        if abort_promise
          Concurrent::Promises.any(future, abort_promise)
        else
          future
        end
      result
        .then { |value| cleanup.call; value }
        .rescue { |error| cleanup.call; raise error }
    end

    def self.debug_error(error)
      # TODO
    end

    # TODO
    # * @template T
    # * @param {!Promise<T>} promise
    # * @param {string} taskName
    # * @param {number} timeout
    # * @return {!Promise<T>}
    #
    def self.wait_with_timeout(future, task_name, timeout)
      return future if timeout.nil?

      Concurrent::Promises.future do
        timeout_future = Concurrent::Promises.resolvable_future
        timeout_task = Concurrent::ScheduledTask.execute(timeout) do
          timeout_future.reject Timeout::Error.new("waiting for #{task_name} failed: timeout #{timeout}s exceeded.")
        end
        begin
          Concurrent::Promises.any(future, timeout_future).value!
        ensure
          timeout_task.cancel
        end
      end
    end
  end
end
