module Chromiebara
  class ChromeClient
    include Promise::Await

    CommandCallback = Struct.new(:resolve, :reject, :method)

    include EventEmitter

    attr_reader :web_socket

    # @param [Chromiebara::WebSocketClient] web_socket
    #
    def initialize(web_socket)
      super()
      @web_socket = web_socket
      web_socket.on_message = method :on_message
      @_sessions = {}
      @_last_id = 0
      @command_mutex = Mutex.new
      # Hash<Integer, { resolve: Method, reject: Method, method: String }>
      @_command_callbacks = {}
    end

    # @param [Hash] command
    #
    # TODO
    # @return [Hash]
    #
    def command(command)
      @command_mutex.synchronize do
        comamnd_id = next_command_id
        command = command.merge(id: comamnd_id).to_json

        Promise.new do |resolve, reject|
          @_command_callbacks[comamnd_id] = CommandCallback.new(resolve, reject, command["method"])
          ProtocolLogger.puts_command command
          web_socket.send_message command: command
        end
      end
    end

    # @return [Integer] command_id
    #
    def _raw_send(command)
      @command_mutex.synchronize do
        comamnd_id = next_command_id
        command = command.merge(id: comamnd_id).to_json

        ProtocolLogger.puts_command command
        web_socket.send_message command: command
        comamnd_id
      end
    end

    # @param [Hash] target_info
    #
    # @return [Chromiebara::CDPSession]
    #
    def create_session(target_info)
      response = await command Protocol::Target.attach_to_target target_id: target_info["targetId"], flatten: true

      session_id = response["sessionId"]

      @_sessions.fetch session_id
    end

    private

      def next_command_id
        @_last_id += 1
      end

      # @param [String] message
      #
      def on_message(message)
        message = JSON.parse message

        if message["method"] == Protocol::Target.attached_to_target
          ProtocolLogger.puts_event message
          session_id = message.dig "params", "sessionId"
          session = CDPSession.new(self, message.dig("targetInfo", "type"), session_id)
          @_sessions[session_id] = session
        elsif message["method"] == Protocol::Target.detached_from_target
          session_id = message.dig "params", "sessionId"
          session = @_sessions.fetch session_id
          session.send(:on_close)
          @_sessions.delete session_id
        end

        if message["sessionId"]
          @_sessions.fetch(message["sessionId"]).send(:on_message, message)
        elsif message["id"]
          ProtocolLogger.puts_command_response message
          if callback = @_command_callbacks.delete(message["id"])
            if message.has_key? "error"
              # TODO
              callback.reject.(message["error"])
            else
              callback.resolve.(message["result"])
            end
          end
        else
          ProtocolLogger.puts_event message
          emit(message["method"], message["params"])
        end
      end
  end
end
