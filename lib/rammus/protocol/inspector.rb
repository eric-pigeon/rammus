# frozen_string_literal: true

module Rammus
  module Protocol
    module Inspector
      extend self

      # Disables inspector domain notifications.
      #
      def disable
        {
          method: "Inspector.disable"
        }
      end

      # Enables inspector domain notifications.
      #
      def enable
        {
          method: "Inspector.enable"
        }
      end

      def detached
        'Inspector.detached'
      end

      def target_crashed
        'Inspector.targetCrashed'
      end

      def target_reloaded_after_crash
        'Inspector.targetReloadedAfterCrash'
      end
    end
  end
end
