# frozen_string_literal: true

module Rammus
  module Protocol
    module BackgroundService
      extend self

      # Enables event updates for the service.
      #
      def start_observing(service:)
        {
          method: "BackgroundService.startObserving",
          params: { service: service }.compact
        }
      end

      # Disables event updates for the service.
      #
      def stop_observing(service:)
        {
          method: "BackgroundService.stopObserving",
          params: { service: service }.compact
        }
      end

      # Set the recording state for the service.
      #
      def set_recording(should_record:, service:)
        {
          method: "BackgroundService.setRecording",
          params: { shouldRecord: should_record, service: service }.compact
        }
      end

      # Clears all stored data for the service.
      #
      def clear_events(service:)
        {
          method: "BackgroundService.clearEvents",
          params: { service: service }.compact
        }
      end

      def recording_state_changed
        'BackgroundService.recordingStateChanged'
      end

      def background_service_event_received
        'BackgroundService.backgroundServiceEventReceived'
      end
    end
  end
end
