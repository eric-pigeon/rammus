module Rammus
  module Protocol
    module DOMStorage
      extend self

      def clear(storage_id:)
        {
          method: "DOMStorage.clear",
          params: { storageId: storage_id }.compact
        }
      end

      # Disables storage tracking, prevents storage events from being sent to the client.
      #
      def disable
        {
          method: "DOMStorage.disable"
        }
      end

      # Enables storage tracking, storage events will now be delivered to the client.
      #
      def enable
        {
          method: "DOMStorage.enable"
        }
      end

      def get_dom_storage_items(storage_id:)
        {
          method: "DOMStorage.getDOMStorageItems",
          params: { storageId: storage_id }.compact
        }
      end

      def remove_dom_storage_item(storage_id:, key:)
        {
          method: "DOMStorage.removeDOMStorageItem",
          params: { storageId: storage_id, key: key }.compact
        }
      end

      def set_dom_storage_item(storage_id:, key:, value:)
        {
          method: "DOMStorage.setDOMStorageItem",
          params: { storageId: storage_id, key: key, value: value }.compact
        }
      end

      def dom_storage_item_added
        'DOMStorage.domStorageItemAdded'
      end

      def dom_storage_item_removed
        'DOMStorage.domStorageItemRemoved'
      end

      def dom_storage_item_updated
        'DOMStorage.domStorageItemUpdated'
      end

      def dom_storage_items_cleared
        'DOMStorage.domStorageItemsCleared'
      end
    end
  end
end
