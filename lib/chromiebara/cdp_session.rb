module Chromiebara
  class CDPSession
    attr_reader :client, :target_type, :session_id

    def initialize(client, target_type, session_id)
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
        command_id = client._raw_send command.merge sessionId: session_id

        # TODO this is a race condition, since the command is sent before
        # it's added to the hash this thread could pause, the result could be
        # processed before it's added to the hash
        # command ids are unique per session, so just make this class
        # responsible for the id
        Response.new.tap do |response|
          @_command_callbacks[command_id] = response
        end.await
      end
    end

    private

      # @param [Hash] message
      #
      def on_message(message)
        if message["id"] && callback = @_command_callbacks.fetch(message["id"])
          @_command_callbacks.delete message["id"]
          if message["error"]
            raise 'todo'
          else
            callback.resolve message["result"]
          end
        else
          # TODO
          # emit
          # this.emit(object.method, object.params);
        end
      end
  end
end
