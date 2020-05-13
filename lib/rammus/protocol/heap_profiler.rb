# frozen_string_literal: true

module Rammus
  module Protocol
    module HeapProfiler
      extend self

      # Enables console to refer to the node with given id via $x (see Command Line API for more details
      # $x functions).
      #
      # @param heap_object_id [Heapsnapshotobjectid] Heap snapshot object id to be accessible by means of $x command line API.
      #
      def add_inspected_heap_object(heap_object_id:)
        {
          method: "HeapProfiler.addInspectedHeapObject",
          params: { heapObjectId: heap_object_id }.compact
        }
      end

      def collect_garbage
        {
          method: "HeapProfiler.collectGarbage"
        }
      end

      def disable
        {
          method: "HeapProfiler.disable"
        }
      end

      def enable
        {
          method: "HeapProfiler.enable"
        }
      end

      # @param object_id [Runtime.remoteobjectid] Identifier of the object to get heap object id for.
      #
      def get_heap_object_id(object_id:)
        {
          method: "HeapProfiler.getHeapObjectId",
          params: { objectId: object_id }.compact
        }
      end

      # @param object_group [String] Symbolic group name that can be used to release multiple objects.
      #
      def get_object_by_heap_object_id(object_id:, object_group: nil)
        {
          method: "HeapProfiler.getObjectByHeapObjectId",
          params: { objectId: object_id, objectGroup: object_group }.compact
        }
      end

      def get_sampling_profile
        {
          method: "HeapProfiler.getSamplingProfile"
        }
      end

      # @param sampling_interval [Number] Average sample interval in bytes. Poisson distribution is used for the intervals. The default value is 32768 bytes.
      #
      def start_sampling(sampling_interval: nil)
        {
          method: "HeapProfiler.startSampling",
          params: { samplingInterval: sampling_interval }.compact
        }
      end

      def start_tracking_heap_objects(track_allocations: nil)
        {
          method: "HeapProfiler.startTrackingHeapObjects",
          params: { trackAllocations: track_allocations }.compact
        }
      end

      def stop_sampling
        {
          method: "HeapProfiler.stopSampling"
        }
      end

      # @param report_progress [Boolean] If true 'reportHeapSnapshotProgress' events will be generated while snapshot is being taken when the tracking is stopped.
      #
      def stop_tracking_heap_objects(report_progress: nil)
        {
          method: "HeapProfiler.stopTrackingHeapObjects",
          params: { reportProgress: report_progress }.compact
        }
      end

      # @param report_progress [Boolean] If true 'reportHeapSnapshotProgress' events will be generated while snapshot is being taken.
      #
      def take_heap_snapshot(report_progress: nil)
        {
          method: "HeapProfiler.takeHeapSnapshot",
          params: { reportProgress: report_progress }.compact
        }
      end

      def add_heap_snapshot_chunk
        'HeapProfiler.addHeapSnapshotChunk'
      end

      def heap_stats_update
        'HeapProfiler.heapStatsUpdate'
      end

      def last_seen_object_id
        'HeapProfiler.lastSeenObjectId'
      end

      def report_heap_snapshot_progress
        'HeapProfiler.reportHeapSnapshotProgress'
      end

      def reset_profiles
        'HeapProfiler.resetProfiles'
      end
    end
  end
end
