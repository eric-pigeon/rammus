module Rammus
  # The CDPSession instances are used to talk raw Chrome Devtools Protocol:
  #
  # protocol methods can be called with {CDPSession#command} method.
  # protocol events can be subscribed to with {CDPSession#on} method.
  #
  class CDPSession
    include EventEmitter

    # @!visibility private
    #
    CommandCallback = Struct.new(:resolve, :reject, :method)

    # @!visibility private
    #
    attr_reader :client, :target_type, :session_id

    # @!visibility private
    #
    def initialize(client, target_type, session_id)
      super()
      @client = client
      @target_type = target_type
      @session_id = session_id
      @_command_mutex = Mutex.new
      @_command_callbacks = {}
    end

    # @param [Hash] command
    #
    # @return [Hash]
    #
    def command(command)
      if client.nil?
        return Promise.reject(StandardError.new "Protocol error (#{command[:method]}): Session closed. Most likely the #{target_type} has been closed.")
      end
      @_command_mutex.synchronize do
        client._raw_send(command.merge sessionId: session_id) do |command_id|
          Promise.new do |resolve, reject|
            @_command_callbacks[command_id] = CommandCallback.new(resolve, reject, command[:method])
          end
        end
      end
    end

    private

      # @param [Hash] message
      #
      def on_message(message)
        if message["id"] && callback = @_command_callbacks.fetch(message["id"])
          ProtocolLogger.puts_command_response message
          @_command_callbacks.delete message["id"]
          if message["error"]
            callback.reject.(ChromeClient.create_protocol_error callback.method, message)
          else
            callback.resolve.(message["result"])
          end
        else
          ProtocolLogger.puts_event message
          emit message["method"], message["params"]
        end
      end

      def on_close
        @_command_mutex.synchronize do
          @_command_callbacks.values.each do |callback|
            callback.reject.("Protocol error (#{callback.method}): Target closed.")
          end
          @_command_callbacks.clear
        end
        @client = nil
        emit :cdp_session_disconnected
      end
  end
end
