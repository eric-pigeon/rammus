# frozen_string_literal: true

module Rammus
  # @!visibility private
  #
  class ChromeClient
    include EventEmitter

    CommandCallback = Struct.new(:resolve, :reject, :method)

    def self.from_session(session)
      session.client
    end

    # @param [String] method
    # @param [Hash] object
    #
    def self.create_protocol_error(method, object)
      message = "Protocol error (#{method}): #{object.dig('error', 'message')}"
      message += object.dig("error", "data").to_s
      Errors::ProtocolError.new message
    end

    attr_reader :web_socket

    # @param [Rammus::WebSocketClient] web_socket
    #
    def initialize(web_socket)
      super()
      @web_socket = web_socket
      web_socket.on_message = method :on_message
      web_socket.on_close = method :on_close
      @_sessions = {}
      @_last_id = 0
      @command_mutex = Mutex.new
      # Hash<Integer, { resolve: Method, reject: Method, method: String }>
      @_command_callbacks = {}
      @event_queue = Rammus::EventQueue.new
      @_closed = false
    end

    # @param [Hash] command
    #
    # @return [Concurrent::ResolvableFuture]
    #
    def command(command)
      @command_mutex.synchronize do
        comamnd_id = next_command_id

        Concurrent::Promises.resolvable_future.tap do |future|
          @_command_callbacks[comamnd_id] = CommandCallback.new(
            future.method(:fulfill),
            future.method(:reject),
            command[:method]
          )
          command = command.merge(id: comamnd_id).to_json
          ProtocolLogger.puts_command command
          web_socket.send_message command: command
        end
      end
    end

    # @return [Integer] command_id
    #
    def _raw_send(command, &block)
      @command_mutex.synchronize do
        comamnd_id = next_command_id
        promise = block.call comamnd_id
        command = command.merge(id: comamnd_id).to_json

        ProtocolLogger.puts_command command
        web_socket.send_message command: command
        promise
      end
    end

    # @param [Hash] target_info
    #
    # @return [Rammus::CDPSession]
    #
    def create_session(target_info)
      response = command(Protocol::Target.attach_to_target(target_id: target_info["targetId"], flatten: true)).value

      session_id = response["sessionId"]

      @_sessions.fetch session_id
    end

    def session(session_id)
      @_sessions.fetch session_id
    end

    def dispose
      web_socket.close
    end

    def closed?
      @_closed
    end

    def url
      web_socket.url
    end

    private

      attr_reader :event_queue

      def on_close
        return if @_closed

        @_closed = true

        web_socket.on_message = nil
        web_socket.on_close = nil

        @command_mutex.synchronize do
          @_command_callbacks.each { callback.reject.("Protocol error #{callback.method}: Target closed.") }
          @_command_callbacks.clear
        end

        @_sessions.each { |_, session| session.send :on_close }
        @_sessions.clear

        emit :disconnected
      end

      def next_command_id
        @_last_id += 1
      end

      # @param [String] message
      #
      def on_message(message)
        message = JSON.parse message

        if message["method"] == Protocol::Target.attached_to_target
          session_id = message.dig "params", "sessionId"
          session = CDPSession.new(self, message.dig("params", "targetInfo", "type"), session_id)
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
          if (callback = @_command_callbacks.delete(message["id"]))
            if message.key? "error"
              callback.reject.(ChromeClient.create_protocol_error(callback.method, message))
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
