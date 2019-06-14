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
    def continue(url: nil, method: nil, post_date: nil, headers: nil)
      # Request interception is not supported for data: urls.
      return if self.url.start_with? 'data:'
      raise 'Request Interception is not enabled!' unless @_allow_interception
      raise 'Request is already handled!' if @_interception_handled
      @_interception_handled = true

      await client.command(Protocol::Fetch.continue_request(
        request_id: interception_id,
        url: url,
        method: method,
        post_data: post_data,
        headers: headers_array(headers)
      )).catch do |error|
        # In certain cases, protocol will return error if the request was already canceled
        # or the page was closed. We should tolerate these errors.
       puts 'TODO'
      end
    end

    #/**
    # * @param {!{status: number, headers: Object, contentType: string, body: (string|Buffer)}} response
    # */
    #async respond(response) {
    #  // Mocking responses for dataURL requests is not currently supported.
    #  if (this._url.startsWith('data:'))
    #    return;
    #  assert(this._allowInterception, 'Request Interception is not enabled!');
    #  assert(!this._interceptionHandled, 'Request is already handled!');
    #  this._interceptionHandled = true;

    #  const responseBody = response.body && helper.isString(response.body) ? Buffer.from(/** @type {string} */(response.body)) : /** @type {?Buffer} */(response.body || null);

    #  /** @type {!Object<string, string>} */
    #  const responseHeaders = {};
    #  if (response.headers) {
    #    for (const header of Object.keys(response.headers))
    #      responseHeaders[header.toLowerCase()] = response.headers[header];
    #  }
    #  if (response.contentType)
    #    responseHeaders['content-type'] = response.contentType;
    #  if (responseBody && !('content-length' in responseHeaders))
    #    responseHeaders['content-length'] = String(Buffer.byteLength(responseBody));

    #  await this._client.send('Fetch.fulfillRequest', {
    #    requestId: this._interceptionId,
    #    responseCode: response.status || 200,
    #    responseHeaders: headersArray(responseHeaders),
    #    body: responseBody ? responseBody.toString('base64') : undefined,
    #  }).catch(error => {
    #    // In certain cases, protocol will return error if the request was already canceled
    #    // or the page was closed. We should tolerate these errors.
    #    debugError(error);
    #  });
    #}

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
        # TODO
        # debugError(error);
      end;
    end

    private

      def headers_array(headers = {})
        _result = []
        # TODO
        #for (const name in headers)
        #  result.push({name, value: headers[name] + ''});
        #return result;
      end
  end
end
