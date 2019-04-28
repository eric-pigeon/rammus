require 'websocket/driver'
require 'socket'

module Chromiebara
  class WebSocketClient
    attr_reader :driver, :status

    def initialize(url)
      @socket = Socket.new(url)
      @driver = ::WebSocket::Driver.client(@socket)
      @status = :closed
      @_callbacks = {}
      @listener_thread = nil
      @command_mutex = Mutex.new

      setup_driver
      start_driver
      start_listener_thread
    end

    def send_message(command_id:, command:)
      @command_mutex.synchronize do
        response = Response.new
        @_callbacks[command_id] = response
        driver.text command
        response
      end
    end

    private

      def setup_driver
        driver.on(:message) do |e|
          message = JSON.parse e.data

          puts message
          if message["id"]
            if callback = @_callbacks.delete(message["id"])
              callback.resolve message
            end
          end
        end

        driver.on(:error) do |e|
          raise e.message
        end

        driver.on(:close) do |_e|
          @status = :closed
        end

        driver.on(:open) do |_e|
          @status = :open
        end
      end

      def start_driver
        driver.start
        parse_input until status == :open
      end

      def parse_input
        driver.parse(@socket.read)
      end

      def start_listener_thread
        @listener_thread = Thread.new do
          loop { parse_input }
        end.abort_on_exception = true
      end
  end

  class Socket
    attr_reader :url

    def initialize(url)
      @url = url
      uri = URI.parse(url)
      @io = TCPSocket.new(uri.host, uri.port)
    end

    def write(data)
      @io.print data
    end

    def read
      @io.readpartial(1024)
    end
  end
end
