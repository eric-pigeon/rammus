# frozen_string_literal: true

module Rammus
  module Protocol
    module Performance
      extend self

      # Disable collecting and reporting metrics.
      #
      def disable
        {
          method: "Performance.disable"
        }
      end

      # Enable collecting and reporting metrics.
      #
      def enable
        {
          method: "Performance.enable"
        }
      end

      # Sets time domain to use for collecting and reporting duration metrics.
      # Note that this must be called before enabling metrics collection. Calling
      # this method while metrics collection is enabled returns an error.
      #
      # @param time_domain [String] Time domain
      #
      def set_time_domain(time_domain:)
        {
          method: "Performance.setTimeDomain",
          params: { timeDomain: time_domain }.compact
        }
      end

      # Retrieve current values of run-time metrics.
      #
      def get_metrics
        {
          method: "Performance.getMetrics"
        }
      end

      def metrics
        'Performance.metrics'
      end
    end
  end
end
