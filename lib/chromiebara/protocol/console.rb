module Chromiebara
  module Protocol
    module Console
      extend self

      # Does nothing.
      # 
      #
      def clear_messages
        {
          method: "Console.clearMessages"
        }
      end

      # Disables console domain, prevents further console messages from being reported to the client.
      # 
      #
      def disable
        {
          method: "Console.disable"
        }
      end

      # Enables console domain, sends the messages collected so far to the client by means of the
      # `messageAdded` notification.
      # 
      #
      def enable
        {
          method: "Console.enable"
        }
      end
    end
  end
end
