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

    def initialize(web_socket)
      @web_socket = web_socket
      @last_id = 0
    end

    # @param [Hash] command
    #
    # @raise [CommandError]
    #
    # @return [Hash]
    #
    def command(command)
      command = command.merge(id: next_command_id).to_json

      # TODO
      puts "#{Time.now.to_i}: sending msg: #{command}"
      @web_socket.send_message command
      message = @web_socket.read_message
      puts message
      response = JSON.parse(message)

      if response.has_key? "error"
        raise CommandError.new code: response["error"]["code"], message: response["error"]["message"]
      end

      response["result"] || response["error"]
    end

    private

      def next_command_id
        @last_id += 1
      end
  end
end
