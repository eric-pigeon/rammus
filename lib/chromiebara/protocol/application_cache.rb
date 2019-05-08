module Chromiebara
  module Protocol
    module ApplicationCache
      extend self

      # Enables application cache domain notifications.
      #
      def enable
        {
          method: "ApplicationCache.enable"
        }
      end

      # Returns relevant application cache data for the document in given frame.
      #
      # @param frame_id [Page.frameid] Identifier of the frame containing document whose application cache is retrieved.
      #
      def get_application_cache_for_frame(frame_id:)
        {
          method: "ApplicationCache.getApplicationCacheForFrame",
          params: { frameId: frame_id }.compact
        }
      end

      # Returns array of frame identifiers with manifest urls for each frame containing a document
      # associated with some application cache.
      #
      def get_frames_with_manifests
        {
          method: "ApplicationCache.getFramesWithManifests"
        }
      end

      # Returns manifest URL for document in the given frame.
      #
      # @param frame_id [Page.frameid] Identifier of the frame containing document whose manifest is retrieved.
      #
      def get_manifest_for_frame(frame_id:)
        {
          method: "ApplicationCache.getManifestForFrame",
          params: { frameId: frame_id }.compact
        }
      end

      def application_cache_status_updated
        'ApplicationCache.applicationCacheStatusUpdated'
      end

      def network_state_updated
        'ApplicationCache.networkStateUpdated'
      end
    end
  end
end
