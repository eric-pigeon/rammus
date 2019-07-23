module Rammus
  module Protocol
    module IndexedDB
      extend self

      # Clears all entries from an object store.
      #
      # @param security_origin [String] Security origin.
      # @param database_name [String] Database name.
      # @param object_store_name [String] Object store name.
      #
      def clear_object_store(security_origin:, database_name:, object_store_name:)
        {
          method: "IndexedDB.clearObjectStore",
          params: { securityOrigin: security_origin, databaseName: database_name, objectStoreName: object_store_name }.compact
        }
      end

      # Deletes a database.
      #
      # @param security_origin [String] Security origin.
      # @param database_name [String] Database name.
      #
      def delete_database(security_origin:, database_name:)
        {
          method: "IndexedDB.deleteDatabase",
          params: { securityOrigin: security_origin, databaseName: database_name }.compact
        }
      end

      # Delete a range of entries from an object store
      #
      # @param key_range [Keyrange] Range of entry keys to delete
      #
      def delete_object_store_entries(security_origin:, database_name:, object_store_name:, key_range:)
        {
          method: "IndexedDB.deleteObjectStoreEntries",
          params: { securityOrigin: security_origin, databaseName: database_name, objectStoreName: object_store_name, keyRange: key_range }.compact
        }
      end

      # Disables events from backend.
      #
      def disable
        {
          method: "IndexedDB.disable"
        }
      end

      # Enables events from backend.
      #
      def enable
        {
          method: "IndexedDB.enable"
        }
      end

      # Requests data from object store or index.
      #
      # @param security_origin [String] Security origin.
      # @param database_name [String] Database name.
      # @param object_store_name [String] Object store name.
      # @param index_name [String] Index name, empty string for object store data requests.
      # @param skip_count [Integer] Number of records to skip.
      # @param page_size [Integer] Number of records to fetch.
      # @param key_range [Keyrange] Key range.
      #
      def request_data(security_origin:, database_name:, object_store_name:, index_name:, skip_count:, page_size:, key_range: nil)
        {
          method: "IndexedDB.requestData",
          params: { securityOrigin: security_origin, databaseName: database_name, objectStoreName: object_store_name, indexName: index_name, skipCount: skip_count, pageSize: page_size, keyRange: key_range }.compact
        }
      end

      # Requests database with given name in given frame.
      #
      # @param security_origin [String] Security origin.
      # @param database_name [String] Database name.
      #
      def request_database(security_origin:, database_name:)
        {
          method: "IndexedDB.requestDatabase",
          params: { securityOrigin: security_origin, databaseName: database_name }.compact
        }
      end

      # Requests database names for given security origin.
      #
      # @param security_origin [String] Security origin.
      #
      def request_database_names(security_origin:)
        {
          method: "IndexedDB.requestDatabaseNames",
          params: { securityOrigin: security_origin }.compact
        }
      end
    end
  end
end
