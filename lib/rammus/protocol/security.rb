# frozen_string_literal: true

module Rammus
  module Protocol
    module Security
      extend self

      # Disables tracking security state changes.
      #
      def disable
        {
          method: "Security.disable"
        }
      end

      # Enables tracking security state changes.
      #
      def enable
        {
          method: "Security.enable"
        }
      end

      # Enable/disable whether all certificate errors should be ignored.
      #
      # @param ignore [Boolean] If true, all certificate errors will be ignored.
      #
      def set_ignore_certificate_errors(ignore:)
        {
          method: "Security.setIgnoreCertificateErrors",
          params: { ignore: ignore }.compact
        }
      end

      # Handles a certificate error that fired a certificateError event.
      #
      # @param event_id [Integer] The ID of the event.
      # @param action [Certificateerroraction] The action to take on the certificate error.
      #
      def handle_certificate_error(event_id:, action:)
        {
          method: "Security.handleCertificateError",
          params: { eventId: event_id, action: action }.compact
        }
      end

      # Enable/disable overriding certificate errors. If enabled, all certificate error events need to
      # be handled by the DevTools client and should be answered with `handleCertificateError` commands.
      #
      # @param override [Boolean] If true, certificate errors will be overridden.
      #
      def set_override_certificate_errors(override:)
        {
          method: "Security.setOverrideCertificateErrors",
          params: { override: override }.compact
        }
      end

      def certificate_error
        'Security.certificateError'
      end

      def security_state_changed
        'Security.securityStateChanged'
      end
    end
  end
end
