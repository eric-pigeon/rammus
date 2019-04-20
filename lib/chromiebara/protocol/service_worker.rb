module Chromiebara
  module Protocol
    module ServiceWorker
      extend self


      # 
      #
      def deliver_push_message(origin:, registration_id:, data:)
        {
          method: "ServiceWorker.deliverPushMessage",
          params: { origin: origin, registrationId: registration_id, data: data }.compact
        }
      end


      # 
      #
      def disable
        {
          method: "ServiceWorker.disable"
        }
      end


      # 
      #
      def dispatch_sync_event(origin:, registration_id:, tag:, last_chance:)
        {
          method: "ServiceWorker.dispatchSyncEvent",
          params: { origin: origin, registrationId: registration_id, tag: tag, lastChance: last_chance }.compact
        }
      end


      # 
      #
      def enable
        {
          method: "ServiceWorker.enable"
        }
      end


      # 
      #
      def inspect_worker(version_id:)
        {
          method: "ServiceWorker.inspectWorker",
          params: { versionId: version_id }.compact
        }
      end


      # 
      #
      def set_force_update_on_page_load(force_update_on_page_load:)
        {
          method: "ServiceWorker.setForceUpdateOnPageLoad",
          params: { forceUpdateOnPageLoad: force_update_on_page_load }.compact
        }
      end


      # 
      #
      def skip_waiting(scope_url:)
        {
          method: "ServiceWorker.skipWaiting",
          params: { scopeURL: scope_url }.compact
        }
      end


      # 
      #
      def start_worker(scope_url:)
        {
          method: "ServiceWorker.startWorker",
          params: { scopeURL: scope_url }.compact
        }
      end


      # 
      #
      def stop_all_workers
        {
          method: "ServiceWorker.stopAllWorkers"
        }
      end


      # 
      #
      def stop_worker(version_id:)
        {
          method: "ServiceWorker.stopWorker",
          params: { versionId: version_id }.compact
        }
      end


      # 
      #
      def unregister(scope_url:)
        {
          method: "ServiceWorker.unregister",
          params: { scopeURL: scope_url }.compact
        }
      end


      # 
      #
      def update_registration(scope_url:)
        {
          method: "ServiceWorker.updateRegistration",
          params: { scopeURL: scope_url }.compact
        }
      end
    end
  end
end
