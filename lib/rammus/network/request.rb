module Rammus
  module Network
    # Whenever the page sends a request, such as for a network resource, the
    # following events are emitted by puppeteer's page:
    #
    # * :request emitted when the request is issued by the page.
    # * :response emitted when/if the response is received for the request.
    # * :requestfinished emitted when the response body is downloaded and the
    #   request is complete.
    #
    # If request fails at some point, then instead of :requestfinished event
    # (and possibly instead of :response event), the :requestfailed event is
    # emitted.
    #
    # @note HTTP Error responses, such as 404 or 503, are still successful
    # responses from HTTP standpoint, so request will complete with
    # :requestfinished event.
    #
    # If request gets a :redirect response, the request is successfully
    # finished with the :requestfinished event, and a new request is issued to
    # a redirected url.
    #
    class Request
      include Promise::Await

      # Frame that initiated this request, or nil if navigating to error pages.
      #
      # @return [nil, Frame]
      #
      attr_reader :frame

      # HTTP headers associated with the request. All header names are lower-case.
      #
      # @return [Hash]
      #
      attr_reader :headers

      # Whether this request is driving frame's navigation.
      #
      # @return [Boolean]
      #
      attr_reader :is_navigation_request

      # Request's method (GET, POST, etc.)
      #
      # @return [String]
      #
      attr_reader :method

      # Request's post body, if any.
      #
      # @return [String]
      #
      attr_reader :post_data

      # A redirect_chain is a chain of requests initiated to fetch a resource.
      #
      # If there are no redirects and the request was successful, the chain
      # will be empty.
      #
      # If a server responds with at least a single redirect, then the chai
      # will contain all the requests that were redirected.
      # redirect_chain is shared between all the requests of the same chain.
      #
      # @example the website http://example.com has a single redirect to https://example.com, then the chain will contain one request:
      #   response = await page.goto 'http://example.com'
      #   chain = response.request.redirect_chain(
      #   puts chain.length # 1
      #   puts chain[0].url # 'http://example.com'
      #
      # @example the website https://google.com has no redirects, then the chain will be empty
      #   response = await page.goto 'https://google.com'
      #   chain = response.request.redirect_chain
      #   puts chain.length # 0
      #
      # @return [Array<Request>]
      #
      attr_reader :redirect_chain

      # Contains the request's resource type as it was perceived by the
      # rendering engine. ResourceType will be one of the following: document,
      # stylesheet, image, media, font, script, texttrack, xhr, fetch,
      # eventsource, websocket, manifest, other.
      #
      # @return [String]
      #
      attr_reader :resource_type

      # URL of the request
      #
      # @return [String]
      #
      attr_reader :url

      # @!visibility private
      #

      attr_reader :request_id, :interception_id
      # @!visibility private
      #
      attr_accessor :from_memory_cache, :failure_text

      # @!visibility private
      #
      # @param client [Rammus::CDPSession]
      # @param frame [Rammus::Frame]
      # @param interception_id [String]
      # @param allow_interception [Boolean]
      # @param event [Protocol::Network.requestWillBeSentPayload]
      # @param redirect_chain [Array<Request>]
      #
      def initialize(client, frame, interception_id, allow_interception, event, redirect_chain)
        @client = client
        @request_id = event["requestId"]
        @is_navigation_request = event["requestId"] == event["loaderId"] && event["type"] == 'Document'
        @interception_id = interception_id
        @_allow_interception = allow_interception
        @_interception_handled = false
        @response = nil
        @failure_text = nil
        @_response = nil

        @url = event["request"]["url"]
        @resource_type = event["type"].downcase
        @method = event["request"]["method"]
        @post_data = event["request"]["postData"]
        @frame = frame
        @redirect_chain = redirect_chain
        @headers = event["request"].fetch("headers", {}).map do |key, value|
          [key.downcase, value]
        end.to_h

        @from_memory_cache = false
      end

      # The method returns nil unless this request was failed, as reported by
      # requestfailed event.
      #
      # @example logging all failed requests
      #   page.on :requestfailed', -> (request) do
      #     puts "#{request.url} #{request.failure[:error_text]}"
      #   end
      #
      # @return [nil, Hash<error_text: String>]
      #
      def failure
        return if failure_text.nil?
        { error_text: failure_text }
      end

      # Continues request with optional request overrides. To use this, request
      # interception should be enabled with {Page#set_request_interception}.
      # Exception is immediately thrown if the request interception is not
      # enabled.
      #
      # @example
      #   page.set_request_interception true
      #   page.on :request, -> (request) do
      #     # Override headers
      #     headers = request.headers.merge(
      #       foo: 'bar', # set "foo" header
      #       origin: nil, # remove "origin" header
      #     )
      #     request.continue headers: headers
      #   end
      #
      # @param url [String] If set, the request url will be changed. This is
      #   not a redirect. The request will be silently forwarded to the new url.
      #   For example, the address bar will show the original url.
      # @param method [String] If set changes the request method (e.g. GET or
      #   POST)
      # @param post_data [String] If set changes the post data of request
      # @param headers [Hash] If set changes the request HTTP headers. Header
      #   values will be converted to a string.
      #
      # @return [nil]
      #
      def continue(url: nil, method: nil, post_data: nil, headers: nil)
        # Request interception is not supported for data: urls.
        return if self.url.start_with? 'data:'
        raise 'Request Interception is not enabled!' unless @_allow_interception
        raise 'Request is already handled!' if @_interception_handled
        @_interception_handled = true

        await(client.command(Protocol::Fetch.continue_request(
          request_id: interception_id,
          url: url,
          method: method,
          post_data: post_data,
          headers: headers_array(headers)
        )).catch do |error|
          # In certain cases, protocol will return error if the request was already canceled
          # or the page was closed. We should tolerate these errors.
        end)
        nil
      end

      # Fulfills request with given response. To use this, request interception
      # should be enabled with {Page#set_request_interception}. Exception is
      # thrown if request interception is not enabled
      #
      # @example fulfilling all requests with 404 responses
      #   page.set_request_interception true
      #   page.on :request, -> (request) do
      #     request.respond(
      #       status: 404,
      #       contentType: 'text/plain',
      #       body: 'Not Found!'
      #     )
      #   end
      #
      # @note Mocking responses for dataURL requests is not supported. Calling
      #   {Request#respond} for a dataURL request is a noop.
      #
      # @param status [Integer] Response status code, defaults to 200.
      # @param headers [Hash] Optional response headers. Header values will be
      #   converted to a string.
      # @param content_type [String] If set, equals to setting Content-Type
      #   response header
      # @param body [String] Optional response body
      #
      # @return [nil]
      #
      def respond(status: nil, headers: {}, content_type: nil, body: nil)
        # Mocking responses for dataURL requests is not currently supported.
        return if self.url.start_with? 'data:'
        raise 'Request Interception is not enabled!' unless @_allow_interception
        raise 'Request is already handled!' if @_interception_handled
        @_interception_handled = true

        # @type {!Object<string, string>}
        response_headers = headers.map { |header, value| [header.downcase, value] }.to_h
        response_headers['content-type'] = content_type unless content_type.nil?
        response_headers['content-length'] ||= body.bytesize.to_s unless body.nil?
        status ||= 200

        await(client.command(Protocol::Fetch.fulfill_request(
          request_id: interception_id,
          response_code: status,
          response_phrase: STATUS_TEXTS[status],
          response_headers: headers_array(response_headers),
          body: Base64.strict_encode64(body || '')
        )).catch do |error|
          # In certain cases, protocol will return error if the request was already canceled
          # or the page was closed. We should tolerate these errors.
          Util.debug_error error
        end)
        nil
      end

      # The request's {Response}  or nil if the response has not been received
      # yet.
      #
      # @return [Response]
      #
      def response
        @_response
      end

      # Aborts request. To use this, request interception should be enabled with
      # {Page#set_request_interception}. Exception is immediately thrown if the
      # request interception is not enabled.
      #
      # @param error_code [Symbol]  Optional error code. Defaults to :failed,
      #   could be one of the following:
      #   * :aborted - An operation was aborted (due to user action)
      #   * :access_denied - Permission to access a resource, other than the
      #     network, was denied
      #   * :address_unreachable - The IP address is unreachable. This usually
      #     means that there is no route to the specified host or network.
      #   * :blocked_by_client - The client chose to block the request.
      #   * :blocked_by_response - The request failed because the response was
      #     delivered along with requirements which are not met
      #     ('X-Frame-Options' and 'Content-Security-Policy' ancestor checks,
      #     for instance).
      #   * :connection_aborted - A connection timed out as a result of not
      #     receiving an ACK for data sent.
      #   * :connection_closed - A connection was closed (corresponding to a
      #     TCP FIN).
      #   * :connection_failed - A connection attempt failed.
      #   * :connection_refused - A connection attempt was refused.
      #   * :connection_reset - A connection was reset (corresponding to a TCP
      #     RST).
      #   * :internet_disconnected - The Internet connection has been lost.
      #   * :namenot_resolved - The host name could not be resolved.
      #   * :timedout - An operation timed out.
      #   * :failed - A generic failure occurred.
      #
      # @return [nil]
      #
      def abort(error_code = :failed)
        # Request interception is not supported for data: urls.
        return if self.url.start_with? 'data:'
        error_reason = ERROR_REASONS[error_code]
        raise "Unknown error code: #{error_code}" if error_reason.nil?
        raise 'Request Interception is not enabled!' unless @_allow_interception
        raise 'Request is already handled!' if @_interception_handled
        @_interception_handled = true
        await client.command(Protocol::Fetch.fail_request(
          request_id: interception_id,
          error_reason: error_reason
        )).catch do |error|
          # In certain cases, protocol will return error if the request was already canceled
          # or the page was closed. We should tolerate these errors.
          Util.debug_error error
        end
        nil
      end

      # @!visibility private
      #
      def _response=(response)
        @_response = response
      end

      private

        attr_reader :client

        ERROR_REASONS = {
          aborted: 'Aborted',
          access_denied: 'AccessDenied',
          address_unreachable: 'AddressUnreachable',
          blocked_by_client: 'BlockedByClient',
          blocked_by_response: 'BlockedByResponse',
          connection_aborted: 'ConnectionAborted',
          connection_closed: 'ConnectionClosed',
          connection_failed: 'ConnectionFailed',
          connection_refused: 'ConnectionRefused',
          connection_reset: 'ConnectionReset',
          internet_disconnected: 'InternetDisconnected',
          name_not_resolved: 'NameNotResolved',
          timed_out: 'TimedOut',
          failed: 'Failed',
        }

        def headers_array(headers = {})
          return if headers.nil?

          headers.map do |name, value|
            { name: name, value: value.to_s }
          end
        end

        STATUS_TEXTS = {
          100 => 'Continue',
          101 => 'Switching Protocols',
          102 => 'Processing',
          103 => 'Early Hints',
          200 => 'OK',
          201 => 'Created',
          202 => 'Accepted',
          203 => 'Non-Authoritative Information',
          204 => 'No Content',
          205 => 'Reset Content',
          206 => 'Partial Content',
          207 => 'Multi-Status',
          208 => 'Already Reported',
          226 => 'IM Used',
          300 => 'Multiple Choices',
          301 => 'Moved Permanently',
          302 => 'Found',
          303 => 'See Other',
          304 => 'Not Modified',
          305 => 'Use Proxy',
          306 => 'Switch Proxy',
          307 => 'Temporary Redirect',
          308 => 'Permanent Redirect',
          400 => 'Bad Request',
          401 => 'Unauthorized',
          402 => 'Payment Required',
          403 => 'Forbidden',
          404 => 'Not Found',
          405 => 'Method Not Allowed',
          406 => 'Not Acceptable',
          407 => 'Proxy Authentication Required',
          408 => 'Request Timeout',
          409 => 'Conflict',
          410 => 'Gone',
          411 => 'Length Required',
          412 => 'Precondition Failed',
          413 => 'Payload Too Large',
          414 => 'URI Too Long',
          415 => 'Unsupported Media Type',
          416 => 'Range Not Satisfiable',
          417 => 'Expectation Failed',
          418 => 'I\'m a teapot',
          421 => 'Misdirected Request',
          422 => 'Unprocessable Entity',
          423 => 'Locked',
          424 => 'Failed Dependency',
          425 => 'Too Early',
          426 => 'Upgrade Required',
          428 => 'Precondition Required',
          429 => 'Too Many Requests',
          431 => 'Request Header Fields Too Large',
          451 => 'Unavailable For Legal Reasons',
          500 => 'Internal Server Error',
          501 => 'Not Implemented',
          502 => 'Bad Gateway',
          503 => 'Service Unavailable',
          504 => 'Gateway Timeout',
          505 => 'HTTP Version Not Supported',
          506 => 'Variant Also Negotiates',
          507 => 'Insufficient Storage',
          508 => 'Loop Detected',
          510 => 'Not Extended',
          511 => 'Network Authentication Required'
        }
    end
  end
end
