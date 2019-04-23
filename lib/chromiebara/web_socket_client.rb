require 'websocket/driver'
require 'socket'

module Chromiebara
  class WebSocketClient
    attr_reader :driver, :messages, :status

    def initialize(url)
      @socket = Socket.new(url)
      @driver = ::WebSocket::Driver.client(@socket)
      @status = :closed
      @messages = []

      setup_driver
      start_driver
    end

    def send_message(json)
      driver.text json
    end

    def read_message
      parse_input until (message = messages.shift)
      message
    end

    private

      def setup_driver
        driver.on(:message) do |e|
          messages << e.data
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
        # TODO
        puts "WS opened"
      end

      def parse_input
        driver.parse(@socket.read)
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
