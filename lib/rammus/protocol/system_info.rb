# frozen_string_literal: true

module Rammus
  module Protocol
    module SystemInfo
      extend self

      # Returns information about the system.
      #
      def get_info
        {
          method: "SystemInfo.getInfo"
        }
      end

      # Returns information about all running processes.
      #
      def get_process_info
        {
          method: "SystemInfo.getProcessInfo"
        }
      end
    end
  end
end
