# frozen_string_literal: true

module Rammus
  module Network
    class Response
      attr_reader :client, :request, :url, :status, :status_text,
        :from_service_worker, :body_loaded_promise_fulfill, :remote_address

      def initialize(client, request, response_payload)
        @client = client
        @request = request
        # this._contentPromise = null;

        @_body_loaded_promise = Concurrent::Promises.resolvable_future
        @body_loaded_promise_fulfill = @_body_loaded_promise.method(:fulfill)

        @remote_address = {
          ip: response_payload["remoteIPAddress"],
          port: response_payload["remotePort"]
        }
        @status = response_payload["status"]
        @status_text = response_payload["statusText"]
        @url = request.url
        @_from_disk_cache = !!response_payload["fromDiskCache"]
        @from_service_worker = !!response_payload["fromServiceWorker"]
        @_headers = response_payload.fetch("headers", {}).map do |name, value|
          [name.downcase, value]
        end.to_h
        # this._securityDetails = responsePayload.securityDetails ? new SecurityDetails(responsePayload.securityDetails) : null;
      end

      # @return {boolean}
      #
      def ok?
        status.zero? || status >= 200 && status <= 299
      end

      # @return {!Object}
      #
      def headers
        @_headers.dup
      end

      # * @return {?SecurityDetails}
      # */
      # securityDetails() {
      #  return this._securityDetails;
      # }

      def buffer
        @_buffer ||= @_body_loaded_promise.then do |error|
          raise error if error

          response = client.command(Protocol::Network.get_response_body(request_id: request.request_id)).value!
          if response["base64Encoded"]
            Base64.decode64 response["body"]
          else
            response["body"]
          end
        end
      end
      alias text buffer

      def json
        text.then { |content| JSON.parse content }
      end

      # @return [Boolean]
      #
      def from_cache
        @_from_disk_cache || request.from_memory_cache
      end

      # * @return {boolean}
      # */
      # fromServiceWorker() {
      #  return this._fromServiceWorker;
      # }

      # @return {?Puppeteer.Frame}
      #
      def frame
        request.frame
      end
    end
  end
end
