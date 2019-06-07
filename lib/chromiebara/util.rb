module Chromiebara
  module Util
    # [Protocol.Runtime.RemoteObject] remote_object
    #
    def self.value_from_remote_object(remote_object)
      raise "Cannot extract value when objectId is given" if remote_object["objectId"]
      if remote_object["unserializableValue"]
        # if (remoteObject.type === 'bigint' && typeof BigInt !== 'undefined')
        #   return BigInt(remoteObject.unserializableValue.replace('n', ''));
        case remote_object["unserializableValue"]
        when '-0'
          raise 'TODO'
        when 'NaN'
          raise 'TODO'
        when 'Infinity'
          return Float::INFINITY
        when '-Infinity'
          return -Float::INFINITY
        else
          raise "Unsupported unserializable value #{remote_object["unserializableValue"]}"
        end
      end
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
        return exception_details.dig("exception", "description") || exception.dig("exception", "value")
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
  end
end
