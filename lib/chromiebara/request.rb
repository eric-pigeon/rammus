module Chromiebara
  class Request

    attr_reader :client, :url, :frame, :is_navigation_request, :headers, :post_data
    attr_accessor :response, :from_memory_cache

    # @param {!Puppeteer.CDPSession} client
    # @param {?Puppeteer.Frame} frame
    # @param {string} interceptionId
    # @param {boolean} allowInterception
    # @param {!Protocol.Network.requestWillBeSentPayload} event
    # @param {!Array<!Request>} redirectChain
    #
    def initialize(client, frame, interceptionId, allowInterception, event, redirectChain)
      @client = client
      #this._requestId = event.requestId;
      @is_navigation_request = event["requestId"] == event["loaderId"] && event["type"] == 'Document'
      #this._interceptionId = interceptionId;
      #this._allowInterception = allowInterception;
      #this._interceptionHandled = false;
      @response = nil
      #this._failureText = null;

      @url = event["request"]["url"]
      #this._resourceType = event.type.toLowerCase();
      #this._method = event.request.method;
      @post_data = event["request"]["postData"]
      @frame = frame
      #this._redirectChain = redirectChain;
      @headers = event["request"].fetch("headers", {}).map do |key, value|
        [key.downcase, value]
      end.to_h

      @from_memory_cache = false
    end

    #/**
    # * @return {string}
    # */
    #resourceType() {
    #  return this._resourceType;
    #}

    #/**
    # * @return {string}
    # */
    #method() {
    #  return this._method;
    #}

    #/**
    # * @return {!Array<!Request>}
    # */
    #redirectChain() {
    #  return this._redirectChain.slice();
    #}

    #/**
    # * @return {?{errorText: string}}
    # */
    #failure() {
    #  if (!this._failureText)
    #    return null;
    #  return {
    #    errorText: this._failureText
    #  };
    #}

    #/**
    # * @param {!{url?: string, method?:string, postData?: string, headers?: !Object}} overrides
    # */
    #async continue(overrides = {}) {
    #  // Request interception is not supported for data: urls.
    #  if (this._url.startsWith('data:'))
    #    return;
    #  assert(this._allowInterception, 'Request Interception is not enabled!');
    #  assert(!this._interceptionHandled, 'Request is already handled!');
    #  const {
    #    url,
    #    method,
    #    postData,
    #    headers
    #  } = overrides;
    #  this._interceptionHandled = true;
    #  await this._client.send('Fetch.continueRequest', {
    #    requestId: this._interceptionId,
    #    url,
    #    method,
    #    postData,
    #    headers: headers ? headersArray(headers) : undefined,
    #  }).catch(error => {
    #    // In certain cases, protocol will return error if the request was already canceled
    #    // or the page was closed. We should tolerate these errors.
    #    debugError(error);
    #  });
    #}

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

    #/**
    # * @param {string=} errorCode
    # */
    #async abort(errorCode = 'failed') {
    #  // Request interception is not supported for data: urls.
    #  if (this._url.startsWith('data:'))
    #    return;
    #  const errorReason = errorReasons[errorCode];
    #  assert(errorReason, 'Unknown error code: ' + errorCode);
    #  assert(this._allowInterception, 'Request Interception is not enabled!');
    #  assert(!this._interceptionHandled, 'Request is already handled!');
    #  this._interceptionHandled = true;
    #  await this._client.send('Fetch.failRequest', {
    #    requestId: this._interceptionId,
    #    errorReason
    #  }).catch(error => {
    #    // In certain cases, protocol will return error if the request was already canceled
    #    // or the page was closed. We should tolerate these errors.
    #    debugError(error);
    #  });
    #}
  end
end
