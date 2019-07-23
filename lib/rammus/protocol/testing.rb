module Rammus
  module Protocol
    module Testing
      extend self

      # Generates a report for testing.
      #
      # @param message [String] Message to be displayed in the report.
      # @param group [String] Specifies the endpoint group to deliver the report to.
      #
      def generate_test_report(message:, group: nil)
        {
          method: "Testing.generateTestReport",
          params: { message: message, group: group }.compact
        }
      end
    end
  end
end
