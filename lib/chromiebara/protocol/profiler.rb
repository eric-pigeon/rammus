module Chromiebara
  module Protocol
    module Profiler
      extend self


      # 
      #
      def disable
        {
          method: "Profiler.disable"
        }
      end


      # 
      #
      def enable
        {
          method: "Profiler.enable"
        }
      end

      # Collect coverage data for the current isolate. The coverage data may be incomplete due to
      # garbage collection.
      # 
      #
      def get_best_effort_coverage
        {
          method: "Profiler.getBestEffortCoverage"
        }
      end

      # Changes CPU profiler sampling interval. Must be called before CPU profiles recording started.
      # 
      # @param interval [Integer] New sampling interval in microseconds.
      #
      def set_sampling_interval(interval:)
        {
          method: "Profiler.setSamplingInterval",
          params: { interval: interval }.compact
        }
      end


      # 
      #
      def start
        {
          method: "Profiler.start"
        }
      end

      # Enable precise code coverage. Coverage data for JavaScript executed before enabling precise code
      # coverage may be incomplete. Enabling prevents running optimized code and resets execution
      # counters.
      # 
      # @param call_count [Boolean] Collect accurate call counts beyond simple 'covered' or 'not covered'.
      # @param detailed [Boolean] Collect block-based coverage.
      #
      def start_precise_coverage(call_count: nil, detailed: nil)
        {
          method: "Profiler.startPreciseCoverage",
          params: { callCount: call_count, detailed: detailed }.compact
        }
      end

      # Enable type profile.
      # 
      #
      def start_type_profile
        {
          method: "Profiler.startTypeProfile"
        }
      end


      # 
      #
      def stop
        {
          method: "Profiler.stop"
        }
      end

      # Disable precise code coverage. Disabling releases unnecessary execution count records and allows
      # executing optimized code.
      # 
      #
      def stop_precise_coverage
        {
          method: "Profiler.stopPreciseCoverage"
        }
      end

      # Disable type profile. Disabling releases type profile data collected so far.
      # 
      #
      def stop_type_profile
        {
          method: "Profiler.stopTypeProfile"
        }
      end

      # Collect coverage data for the current isolate, and resets execution counters. Precise code
      # coverage needs to have started.
      # 
      #
      def take_precise_coverage
        {
          method: "Profiler.takePreciseCoverage"
        }
      end

      # Collect type profile.
      # 
      #
      def take_type_profile
        {
          method: "Profiler.takeTypeProfile"
        }
      end
    end
  end
end
