module Chromiebara
  class ChromeClient
    attr_reader :web_socket

    def initialize(web_socket)
      @web_socket = web_socket
      @last_id = 0
    end

    # @ param [Hash] command
    def command(command)
      command = command.merge(id: next_command_id).to_json

      # TODO
      puts "#{Time.now.to_i}: sending msg: #{command}"
      @web_socket.send_message command
      message = @web_socket.read_message
      puts message
      message
    end

    private

      def next_command_id
        @last_id += 1
      end
  end
end
