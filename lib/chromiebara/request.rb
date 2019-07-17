module Chromiebara
  class Request
    include Promise::Await

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

    attr_reader :client, :request_id, :url, :frame, :is_navigation_request,
      :headers, :post_data, :redirect_chain, :interception_id, :resource_type, :method
    attr_accessor :response, :from_memory_cache, :failure_text

    # @param {!Puppeteer.CDPSession} client
    # @param {?Puppeteer.Frame} frame
    # @param {string} interceptionId
    # @param {boolean} allowInterception
    # @param {!Protocol.Network.requestWillBeSentPayload} event
    # @param {!Array<!Request>} redirectChain
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

    # @return {?{errorText: string}}
    #
    def failure
      return if failure_text.nil?
      { error_text: failure_text }
    end

    # @param {!{url?: string, method?:string, postData?: string, headers?: !Object}} overrides
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
    end

    # @param {!{status: number, headers: Object, content_type: string, body: (string|Buffer)}} response
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
    end

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
      end;
    end

    private

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
