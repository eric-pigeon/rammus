module Chromiebara
  module Protocol
    module Tethering
      extend self

      # Request browser port binding.
      #
      # @param port [Integer] Port number to bind.
      #
      def bind(port:)
        {
          method: "Tethering.bind",
          params: { port: port }.compact
        }
      end

      # Request browser port unbinding.
      #
      # @param port [Integer] Port number to unbind.
      #
      def unbind(port:)
        {
          method: "Tethering.unbind",
          params: { port: port }.compact
        }
      end

      def accepted
        'Tethering.accepted'
      end
    end
  end
end
