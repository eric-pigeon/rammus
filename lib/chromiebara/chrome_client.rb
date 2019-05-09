module Chromiebara
  class ChromeClient
    include EventEmitter

    attr_reader :web_socket

    # @param [Chromiebara::WebSocketClient] web_socket
    #
    def initialize(web_socket)
      super()
      @web_socket = web_socket
      web_socket.on_message = method :on_message
      @_sessions = {}
      @last_id = 0
      @command_mutex = Mutex.new
      @_command_callbacks = {}
    end

    # @param [Hash] command
    #
    # @return [Hash]
    #
    def command(command)
      response = @command_mutex.synchronize do
        comamnd_id = next_command_id
        command = command.merge(id: comamnd_id).to_json

        Response.new.tap do |resp|
          @_command_callbacks[comamnd_id] = resp
          ProtocolLogger.puts_command command
          web_socket.send_message command: command
        end
      end
      response.await
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
      response = command Protocol::Target.attach_to_target target_id: target_info["targetId"], flatten: true

      session_id = response["sessionId"]

      @_sessions.fetch session_id
    end

    private

      def next_command_id
        @last_id += 1
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
        end

        if message["sessionId"]
          @_sessions.fetch(message["sessionId"]).send(:on_message, message)
        elsif message["id"]
          ProtocolLogger.puts_command_response message
          if callback = @_command_callbacks.delete(message["id"])
            callback.resolve message["result"]
          end
        else
          ProtocolLogger.puts_event message
          emit(message["method"], message["params"])
        end
      end
  end
end
