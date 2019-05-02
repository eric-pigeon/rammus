module Chromiebara
  class ChromeClient
    class CommandError < StandardError
      attr_reader :code

      def initialize(code:, message:)
        @code = code
        super message
      end
    end

    attr_reader :web_socket

    # @param Chromiebara::WebSocketClient web_socket
    #
    def initialize(web_socket)
      @web_socket = web_socket
      web_socket.on_message = method :on_message
      @_sessions = {}
      @last_id = 0
      @_command_callbacks = {}
      @_event_callbacks = Hash.new { |h, k| h[k] = [] }
      @command_mutex = Mutex.new
    end

    # @param [Hash] command
    #
    # @raise [CommandError]
    #
    # @return [Hash]
    #
    def command(command)
      response = @command_mutex.synchronize do
        comamnd_id = next_command_id
        command = command.merge(id: comamnd_id).to_json

        Response.new.tap do |resp|
          @_command_callbacks[comamnd_id] = resp
          puts "#{Time.now.to_i}: sending msg: #{command}"
          web_socket.send_message command_id: comamnd_id, command: command
        end
      end
      response.await
    end

    # @param [String] event
    # @param [Callable]
    #
    def on(event, callable)
      @_event_callbacks[event] << callable
    end

    # @param [Hash] target_info
    #
    # @return [Chromiebara::CDPSession]
    #
    def create_session(target_info)
      response = command Protocol::Target.attach_to_target target_id: target_info["targetId"], flatten: true

      session_id = response.dig "result", "sessionId"

      @_sessions.fetch session_id
    end

    private

      def next_command_id
        @last_id += 1
      end

      # @param [String] event
      # @[aram [Hash] data
      #
      def emit(event, data)
        @_event_callbacks[event].each { |callable| callable.call data }
      end

      # @param [String] message
      #
      def on_message(message)
        message = JSON.parse message

        puts message

        if message["method"] === 'Target.attachedToTarget'
          session_id = message.dig "params", "sessionId"
          session = CDPSession.new(self, message.dig("targetInfo", "type"), session_id)
          @_sessions[session_id] = session
        elsif message["id"]
          if callback = @_command_callbacks.delete(message["id"])
            callback.resolve message
          end
        else
          emit(message["method"], message["params"])
        end
      end
  end
end
