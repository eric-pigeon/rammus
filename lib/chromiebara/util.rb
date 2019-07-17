module Chromiebara
  module Util
    extend Promise::Await

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

    def self.add_event_listener(emitter, event_name, handler)
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

      await(client.command(Protocol::Runtime.release_object object_id: remote_object["objectId"]).catch do |error|
        # Exceptions might happen in case of a page been navigated or closed.
        # Swallow these since they are harmless and we don't leak anything in this case.
        debug_error error
      end)
    end

    # @param {!NodeJS.EventEmitter} emitter
    # @param {(string|symbol)} eventName
    # @param {function} predicate
    # @return {!Promise}
    #
    def self.wait_for_event(emitter, event_name, predicate, timeout = nil)
      _event_timeout = nil
      promise, resolve_callback, _reject_callback = Promise.create

      listener = Util.add_event_listener(emitter, event_name, -> (event) do
        next unless predicate.(event)
        Util.remove_event_listeners [listener]
        #cleanup();
        resolve_callback.(event)
      end)

      # TODO
      #if (timeout) {
      #  eventTimeout = setTimeout(() => {
      #    cleanup();
      #    rejectCallback(new TimeoutError('Timeout exceeded while waiting for event'));
      #  }, timeout);
      #}
      #function cleanup() {
      #  Helper.removeEventListeners([listener]);
      #  clearTimeout(eventTimeout);
      #}
      promise
    end

    def self.debug_error(error)
      # TODO
    end
  end
end
