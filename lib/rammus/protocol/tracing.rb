# frozen_string_literal: true

module Rammus
  module Protocol
    module Tracing
      extend self

      # Stop trace events collection.
      #
      def end
        {
          method: "Tracing.end"
        }
      end

      # Gets supported tracing categories.
      #
      def get_categories
        {
          method: "Tracing.getCategories"
        }
      end

      # Record a clock sync marker in the trace.
      #
      # @param sync_id [String] The ID of this clock sync marker
      #
      def record_clock_sync_marker(sync_id:)
        {
          method: "Tracing.recordClockSyncMarker",
          params: { syncId: sync_id }.compact
        }
      end

      # Request a global memory dump.
      #
      def request_memory_dump
        {
          method: "Tracing.requestMemoryDump"
        }
      end

      # Start trace events collection.
      #
      # @param categories [String] Category/tag filter
      # @param options [String] Tracing options
      # @param buffer_usage_reporting_interval [Number] If set, the agent will issue bufferUsage events at this interval, specified in milliseconds
      # @param transfer_mode [String] Whether to report trace events as series of dataCollected events or to save trace to a stream (defaults to `ReportEvents`).
      # @param stream_format [Streamformat] Trace data format to use. This only applies when using `ReturnAsStream` transfer mode (defaults to `json`).
      # @param stream_compression [Streamcompression] Compression format to use. This only applies when using `ReturnAsStream` transfer mode (defaults to `none`)
      #
      def start(categories: nil, options: nil, buffer_usage_reporting_interval: nil, transfer_mode: nil, stream_format: nil, stream_compression: nil, trace_config: nil)
        {
          method: "Tracing.start",
          params: { categories: categories, options: options, bufferUsageReportingInterval: buffer_usage_reporting_interval, transferMode: transfer_mode, streamFormat: stream_format, streamCompression: stream_compression, traceConfig: trace_config }.compact
        }
      end

      def buffer_usage
        'Tracing.bufferUsage'
      end

      def data_collected
        'Tracing.dataCollected'
      end

      def tracing_complete
        'Tracing.tracingComplete'
      end
    end
  end
end
