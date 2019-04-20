module Chromiebara
  module Protocol
    module Storage
      extend self

      # Clears storage for origin.
      # 
      # @param origin [String] Security origin.
      # @param storage_types [String] Comma separated list of StorageType to clear.
      #
      def clear_data_for_origin(origin:, storage_types:)
        {
          method: "Storage.clearDataForOrigin",
          params: { origin: origin, storageTypes: storage_types }.compact
        }
      end

      # Returns usage and quota in bytes.
      # 
      # @param origin [String] Security origin.
      #
      def get_usage_and_quota(origin:)
        {
          method: "Storage.getUsageAndQuota",
          params: { origin: origin }.compact
        }
      end

      # Registers origin to be notified when an update occurs to its cache storage list.
      # 
      # @param origin [String] Security origin.
      #
      def track_cache_storage_for_origin(origin:)
        {
          method: "Storage.trackCacheStorageForOrigin",
          params: { origin: origin }.compact
        }
      end

      # Registers origin to be notified when an update occurs to its IndexedDB.
      # 
      # @param origin [String] Security origin.
      #
      def track_indexed_db_for_origin(origin:)
        {
          method: "Storage.trackIndexedDBForOrigin",
          params: { origin: origin }.compact
        }
      end

      # Unregisters origin from receiving notifications for cache storage.
      # 
      # @param origin [String] Security origin.
      #
      def untrack_cache_storage_for_origin(origin:)
        {
          method: "Storage.untrackCacheStorageForOrigin",
          params: { origin: origin }.compact
        }
      end

      # Unregisters origin from receiving notifications for IndexedDB.
      # 
      # @param origin [String] Security origin.
      #
      def untrack_indexed_db_for_origin(origin:)
        {
          method: "Storage.untrackIndexedDBForOrigin",
          params: { origin: origin }.compact
        }
      end
    end
  end
end
