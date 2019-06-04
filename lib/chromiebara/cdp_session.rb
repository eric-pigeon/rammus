module Chromiebara
  class CDPSession
    include EventEmitter

    CommandCallback = Struct.new(:resolve, :reject, :method)

    attr_reader :client, :target_type, :session_id

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
            callback.reject.(create_protocol_error callback.method, message)
          else
            callback.resolve.(message["result"])
          end
        else
          ProtocolLogger.puts_event message
          emit message["method"], message["params"]
        end
      end

      def on_close
        # for (const callback of this._callbacks.values())
        #   callback.reject(rewriteError(callback.error, `Protocol error (${callback.method}): Target closed.`));
        # this._callbacks.clear();
        # this._connection = null;
        # this.emit(Events.CDPSession.Disconnected);
      end

      # @param [String] method
      # @param [Hash] object
      #
      def create_protocol_error(method, object)
        message = "Protocol error (#{method}): #{object.dig("error", "message")}"
        # TODO
        # if ('data' in object.error)
        #   message += ` ${object.error.data}`;
        ProtocolError.new message
      end
  end
end
