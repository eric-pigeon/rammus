module Chromiebara
  module Protocol
    module Schema
      extend self

      # Returns supported domains.
      #
      def get_domains
        {
          method: "Schema.getDomains"
        }
      end
    end
  end
end
