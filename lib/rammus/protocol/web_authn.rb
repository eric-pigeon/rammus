module Rammus
  module Protocol
    module WebAuthn
      extend self

      # Enable the WebAuthn domain and start intercepting credential storage and
      # retrieval with a virtual authenticator.
      #
      def enable
        {
          method: "WebAuthn.enable"
        }
      end

      # Disable the WebAuthn domain.
      #
      def disable
        {
          method: "WebAuthn.disable"
        }
      end
    end
  end
end
