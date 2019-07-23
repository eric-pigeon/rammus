module Rammus
  module Protocol
    module Log
      extend self

      # Clears the log.
      #
      def clear
        {
          method: "Log.clear"
        }
      end

      # Disables log domain, prevents further log entries from being reported to the client.
      #
      def disable
        {
          method: "Log.disable"
        }
      end

      # Enables log domain, sends the entries collected so far to the client by means of the
      # `entryAdded` notification.
      #
      def enable
        {
          method: "Log.enable"
        }
      end

      # start violation reporting.
      #
      # @param config [Array] Configuration for violations.
      #
      def start_violations_report(config:)
        {
          method: "Log.startViolationsReport",
          params: { config: config }.compact
        }
      end

      # Stop violation reporting.
      #
      def stop_violations_report
        {
          method: "Log.stopViolationsReport"
        }
      end

      def entry_added
        'Log.entryAdded'
      end
    end
  end
end
