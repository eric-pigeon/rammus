# frozen_string_literal: true

module Rammus
  module Protocol
    module Fetch
      extend self

      # Disables the fetch domain.
      #
      def disable
        {
          method: "Fetch.disable"
        }
      end

      # Enables issuing of requestPaused events. A request will be paused until client
      # calls one of failRequest, fulfillRequest or continueRequest/continueWithAuth.
      #
      # @param patterns [Array] If specified, only requests matching any of these patterns will produce fetchRequested event and will be paused until clients response. If not set, all requests will be affected.
      # @param handle_auth_requests [Boolean] If true, authRequired events will be issued and requests will be paused expecting a call to continueWithAuth.
      #
      def enable(patterns: nil, handle_auth_requests: nil)
        {
          method: "Fetch.enable",
          params: { patterns: patterns, handleAuthRequests: handle_auth_requests }.compact
        }
      end

      # Causes the request to fail with specified reason.
      #
      # @param request_id [Requestid] An id the client received in requestPaused event.
      # @param error_reason [Network.errorreason] Causes the request to fail with the given reason.
      #
      def fail_request(request_id:, error_reason:)
        {
          method: "Fetch.failRequest",
          params: { requestId: request_id, errorReason: error_reason }.compact
        }
      end

      # Provides response to the request.
      #
      # @param request_id [Requestid] An id the client received in requestPaused event.
      # @param response_code [Integer] An HTTP response code.
      # @param response_headers [Array] Response headers.
      # @param body [Binary] A response body.
      # @param response_phrase [String] A textual representation of responseCode. If absent, a standard phrase mathcing responseCode is used.
      #
      def fulfill_request(request_id:, response_code:, response_headers:, body: nil, response_phrase: nil)
        {
          method: "Fetch.fulfillRequest",
          params: { requestId: request_id, responseCode: response_code, responseHeaders: response_headers, body: body, responsePhrase: response_phrase }.compact
        }
      end

      # Continues the request, optionally modifying some of its parameters.
      #
      # @param request_id [Requestid] An id the client received in requestPaused event.
      # @param url [String] If set, the request url will be modified in a way that's not observable by page.
      # @param method [String] If set, the request method is overridden.
      # @param post_data [String] If set, overrides the post data in the request.
      # @param headers [Array] If set, overrides the request headrts.
      #
      def continue_request(request_id:, url: nil, method: nil, post_data: nil, headers: nil)
        {
          method: "Fetch.continueRequest",
          params: { requestId: request_id, url: url, method: method, postData: post_data, headers: headers }.compact
        }
      end

      # Continues a request supplying authChallengeResponse following authRequired event.
      #
      # @param request_id [Requestid] An id the client received in authRequired event.
      # @param auth_challenge_response [Authchallengeresponse] Response to with an authChallenge.
      #
      def continue_with_auth(request_id:, auth_challenge_response:)
        {
          method: "Fetch.continueWithAuth",
          params: { requestId: request_id, authChallengeResponse: auth_challenge_response }.compact
        }
      end

      # Causes the body of the response to be received from the server and
      # returned as a single string. May only be issued for a request that
      # is paused in the Response stage and is mutually exclusive with
      # takeResponseBodyForInterceptionAsStream. Calling other methods that
      # affect the request or disabling fetch domain before body is received
      # results in an undefined behavior.
      #
      # @param request_id [Requestid] Identifier for the intercepted request to get body for.
      #
      def get_response_body(request_id:)
        {
          method: "Fetch.getResponseBody",
          params: { requestId: request_id }.compact
        }
      end

      # Returns a handle to the stream representing the response body.
      # The request must be paused in the HeadersReceived stage.
      # Note that after this command the request can't be continued
      # as is -- client either needs to cancel it or to provide the
      # response body.
      # The stream only supports sequential read, IO.read will fail if the position
      # is specified.
      # This method is mutually exclusive with getResponseBody.
      # Calling other methods that affect the request or disabling fetch
      # domain before body is received results in an undefined behavior.
      #
      def take_response_body_as_stream(request_id:)
        {
          method: "Fetch.takeResponseBodyAsStream",
          params: { requestId: request_id }.compact
        }
      end

      def request_paused
        'Fetch.requestPaused'
      end

      def auth_required
        'Fetch.authRequired'
      end
    end
  end
end
