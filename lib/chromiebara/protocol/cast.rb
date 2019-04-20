module Chromiebara
  module Protocol
    module Cast
      extend self

      # Starts observing for sinks that can be used for tab mirroring, and if set,
      # sinks compatible with |presentationUrl| as well. When sinks are found, a
      # |sinksUpdated| event is fired.
      # Also starts observing for issue messages. When an issue is added or removed,
      # an |issueUpdated| event is fired.
      # 
      #
      def enable(presentation_url: nil)
        {
          method: "Cast.enable",
          params: { presentationUrl: presentation_url }.compact
        }
      end

      # Stops observing for sinks and issues.
      # 
      #
      def disable
        {
          method: "Cast.disable"
        }
      end

      # Sets a sink to be used when the web page requests the browser to choose a
      # sink via Presentation API, Remote Playback API, or Cast SDK.
      # 
      #
      def set_sink_to_use(sink_name:)
        {
          method: "Cast.setSinkToUse",
          params: { sinkName: sink_name }.compact
        }
      end

      # Starts mirroring the tab to the sink.
      # 
      #
      def start_tab_mirroring(sink_name:)
        {
          method: "Cast.startTabMirroring",
          params: { sinkName: sink_name }.compact
        }
      end

      # Stops the active Cast session on the sink.
      # 
      #
      def stop_casting(sink_name:)
        {
          method: "Cast.stopCasting",
          params: { sinkName: sink_name }.compact
        }
      end
    end
  end
end
