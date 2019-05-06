module Chromiebara
  module Protocol
    module DeviceOrientation
      extend self

      # Clears the overridden Device Orientation.
      #
      def clear_device_orientation_override
        {
          method: "DeviceOrientation.clearDeviceOrientationOverride"
        }
      end

      # Overrides the Device Orientation.
      #
      # @param alpha [Number] Mock alpha
      # @param beta [Number] Mock beta
      # @param gamma [Number] Mock gamma
      #
      def set_device_orientation_override(alpha:, beta:, gamma:)
        {
          method: "DeviceOrientation.setDeviceOrientationOverride",
          params: { alpha: alpha, beta: beta, gamma: gamma }.compact
        }
      end
    end
  end
end
