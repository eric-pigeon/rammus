module Chromiebara
  module Protocol
    module Inspector
      extend self

      # Disables inspector domain notifications.
      # 
      #
      def disable
        {
          method: "Inspector.disable"
        }
      end

      # Enables inspector domain notifications.
      # 
      #
      def enable
        {
          method: "Inspector.enable"
        }
      end
    end
  end
end
