module Rammus
  module Protocol
    module CacheStorage
      extend self

      # Deletes a cache.
      #
      # @param cache_id [Cacheid] Id of cache for deletion.
      #
      def delete_cache(cache_id:)
        {
          method: "CacheStorage.deleteCache",
          params: { cacheId: cache_id }.compact
        }
      end

      # Deletes a cache entry.
      #
      # @param cache_id [Cacheid] Id of cache where the entry will be deleted.
      # @param request [String] URL spec of the request.
      #
      def delete_entry(cache_id:, request:)
        {
          method: "CacheStorage.deleteEntry",
          params: { cacheId: cache_id, request: request }.compact
        }
      end

      # Requests cache names.
      #
      # @param security_origin [String] Security origin.
      #
      def request_cache_names(security_origin:)
        {
          method: "CacheStorage.requestCacheNames",
          params: { securityOrigin: security_origin }.compact
        }
      end

      # Fetches cache entry.
      #
      # @param cache_id [Cacheid] Id of cache that contains the entry.
      # @param request_url [String] URL spec of the request.
      #
      def request_cached_response(cache_id:, request_url:)
        {
          method: "CacheStorage.requestCachedResponse",
          params: { cacheId: cache_id, requestURL: request_url }.compact
        }
      end

      # Requests data from cache.
      #
      # @param cache_id [Cacheid] ID of cache to get entries from.
      # @param skip_count [Integer] Number of records to skip.
      # @param page_size [Integer] Number of records to fetch.
      # @param path_filter [String] If present, only return the entries containing this substring in the path
      #
      def request_entries(cache_id:, skip_count:, page_size:, path_filter: nil)
        {
          method: "CacheStorage.requestEntries",
          params: { cacheId: cache_id, skipCount: skip_count, pageSize: page_size, pathFilter: path_filter }.compact
        }
      end
    end
  end
end
