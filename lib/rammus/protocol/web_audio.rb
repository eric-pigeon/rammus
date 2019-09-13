module Rammus
  module Protocol
    module WebAudio
      extend self

      # Enables the WebAudio domain and starts sending context lifetime events.
      #
      def enable
        {
          method: "WebAudio.enable"
        }
      end

      # Disables the WebAudio domain.
      #
      def disable
        {
          method: "WebAudio.disable"
        }
      end

      # Fetch the realtime data from the registered contexts.
      #
      def get_realtime_data(context_id:)
        {
          method: "WebAudio.getRealtimeData",
          params: { contextId: context_id }.compact
        }
      end

      def context_created
        'WebAudio.contextCreated'
      end

      def context_destroyed
        'WebAudio.contextDestroyed'
      end

      def context_changed
        'WebAudio.contextChanged'
      end
    end
  end
end
