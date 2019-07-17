require 'websocket/driver'
require 'socket'

module Chromiebara
  class WebSocketClient
    attr_reader :driver, :status
    attr_accessor :on_message, :on_close

    def initialize(url)
      @socket = Socket.new(url)
      @driver = ::WebSocket::Driver.client(@socket)
      @status = :closed
      @on_message = nil
      @on_close = nil
      @listener_thread = nil

      setup_driver
      start_driver
      start_listener_thread
    end

    def send_message(command:)
      driver.text command
    end

    def close
      driver.close
    end

    private

      def setup_driver
        driver.on(:message) do |event|
          on_message.call event.data if on_message
        end

        driver.on(:error) { |e| raise e.message }

        driver.on(:close) do |_e|
          @on_close.call
          @status = :closed
        end

        driver.on(:open) { |_e| @status = :open }
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
          begin
            loop { parse_input }
          rescue EOFError, IOError
          end
        end.tap { |thread| thread.abort_on_exception = true }
      end
  end

  # @!visibility private
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
