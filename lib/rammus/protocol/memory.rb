module Rammus
  module Protocol
    module Memory
      extend self

      def get_dom_counters
        {
          method: "Memory.getDOMCounters"
        }
      end

      def prepare_for_leak_detection
        {
          method: "Memory.prepareForLeakDetection"
        }
      end

      # Simulate OomIntervention by purging V8 memory.
      #
      def forcibly_purge_java_script_memory
        {
          method: "Memory.forciblyPurgeJavaScriptMemory"
        }
      end

      # Enable/disable suppressing memory pressure notifications in all processes.
      #
      # @param suppressed [Boolean] If true, memory pressure notifications will be suppressed.
      #
      def set_pressure_notifications_suppressed(suppressed:)
        {
          method: "Memory.setPressureNotificationsSuppressed",
          params: { suppressed: suppressed }.compact
        }
      end

      # Simulate a memory pressure notification in all processes.
      #
      # @param level [Pressurelevel] Memory pressure level of the notification.
      #
      def simulate_pressure_notification(level:)
        {
          method: "Memory.simulatePressureNotification",
          params: { level: level }.compact
        }
      end

      # Start collecting native memory profile.
      #
      # @param sampling_interval [Integer] Average number of bytes between samples.
      # @param suppress_randomness [Boolean] Do not randomize intervals between samples.
      #
      def start_sampling(sampling_interval: nil, suppress_randomness: nil)
        {
          method: "Memory.startSampling",
          params: { samplingInterval: sampling_interval, suppressRandomness: suppress_randomness }.compact
        }
      end

      # Stop collecting native memory profile.
      #
      def stop_sampling
        {
          method: "Memory.stopSampling"
        }
      end

      # Retrieve native memory allocations profile
      # collected since renderer process startup.
      #
      def get_all_time_sampling_profile
        {
          method: "Memory.getAllTimeSamplingProfile"
        }
      end

      # Retrieve native memory allocations profile
      # collected since browser process startup.
      #
      def get_browser_sampling_profile
        {
          method: "Memory.getBrowserSamplingProfile"
        }
      end

      # Retrieve native memory allocations profile collected since last
      # `startSampling` call.
      #
      def get_sampling_profile
        {
          method: "Memory.getSamplingProfile"
        }
      end
    end
  end
end
