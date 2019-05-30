module Chromiebara
  class NetworkManager
    extend EventEmitter
    include Promise::Await

    attr_reader :client

    # @param [Chromiebara::CDPSession] client
    # @param [Chromiebara::FrameManager] frame_manager
    # @param [Boolean] ignore_https_errors
    #
    def initialize(client, frame_manager, ignore_https_errors)
      super()
      @client = client
      @frame_manager = frame_manager
      @_ignore_https_errors = ignore_https_errors
    #   /** @type {!Map<string, !Request>} */
    #   this._requestIdToRequest = new Map();
    #   /** @type {!Map<string, !Protocol.Network.requestWillBeSentPayload>} */
    #   this._requestIdToRequestWillBeSentEvent = new Map();
    #   /** @type {!Object<string, string>} */
    #   this._extraHTTPHeaders = {};

    #   this._offline = false;

    #   /** @type {?{username: string, password: string}} */
    #   this._credentials = null;
    #   /** @type {!Set<string>} */
    #   this._attemptedAuthentications = new Set();
    #   this._userRequestInterceptionEnabled = false;
    #   this._protocolRequestInterceptionEnabled = false;
    #   this._userCacheDisabled = false;
    #   /** @type {!Map<string, string>} */
    #   this._requestIdToInterceptionId = new Map();

    #   this._client.on('Fetch.requestPaused', this._onRequestPaused.bind(this));
    #   this._client.on('Fetch.authRequired', this._onAuthRequired.bind(this));
    #   this._client.on('Network.requestWillBeSent', this._onRequestWillBeSent.bind(this));
    #   this._client.on('Network.requestServedFromCache', this._onRequestServedFromCache.bind(this));
    #   this._client.on('Network.responseReceived', this._onResponseReceived.bind(this));
    #   this._client.on('Network.loadingFinished', this._onLoadingFinished.bind(this));
    #   this._client.on('Network.loadingFailed', this._onLoadingFailed.bind(this));
    end

    # async initialize() {
    #   await this._client.send('Network.enable');
    #   if (this._ignoreHTTPSErrors)
    #     await this._client.send('Security.setIgnoreCertificateErrors', {ignore: true});
    # }

    # /**
    #  * @param {?{username: string, password: string}} credentials
    #  */
    # async authenticate(credentials) {
    #   this._credentials = credentials;
    #   await this._updateProtocolRequestInterception();
    # }

    # /**
    #  * @param {!Object<string, string>} extraHTTPHeaders
    #  */
    # async setExtraHTTPHeaders(extraHTTPHeaders) {
    #   this._extraHTTPHeaders = {};
    #   for (const key of Object.keys(extraHTTPHeaders)) {
    #     const value = extraHTTPHeaders[key];
    #     assert(helper.isString(value), `Expected value of header "${key}" to be String, but "${typeof value}" is found.`);
    #     this._extraHTTPHeaders[key.toLowerCase()] = value;
    #   }
    #   await this._client.send('Network.setExtraHTTPHeaders', { headers: this._extraHTTPHeaders });
    # }

    # /**
    #  * @return {!Object<string, string>}
    #  */
    # extraHTTPHeaders() {
    #   return Object.assign({}, this._extraHTTPHeaders);
    # }

    # /**
    #  * @param {boolean} value
    #  */
    # async setOfflineMode(value) {
    #   if (this._offline === value)
    #     return;
    #   this._offline = value;
    #   await this._client.send('Network.emulateNetworkConditions', {
    #     offline: this._offline,
    #     // values of 0 remove any active throttling. crbug.com/456324#c9
    #     latency: 0,
    #     downloadThroughput: -1,
    #     uploadThroughput: -1
    #   });
    # }

    # @param [String] user_agent
    #
    def set_user_agent(user_agent)
      await client.command Protocol::Network.set_user_agent_override user_agent: user_agent
    end

    # /**
    #  * @param {boolean} enabled
    #  */
    # async setCacheEnabled(enabled) {
    #   this._userCacheDisabled = !enabled;
    #   await this._updateProtocolCacheDisabled();
    # }

    # /**
    #  * @param {boolean} value
    #  */
    # async setRequestInterception(value) {
    #   this._userRequestInterceptionEnabled = value;
    #   await this._updateProtocolRequestInterception();
    # }

    # async _updateProtocolRequestInterception() {
    #   const enabled = this._userRequestInterceptionEnabled || !!this._credentials;
    #   if (enabled === this._protocolRequestInterceptionEnabled)
    #     return;
    #   this._protocolRequestInterceptionEnabled = enabled;
    #   if (enabled) {
    #     await Promise.all([
    #       this._updateProtocolCacheDisabled(),
    #       this._client.send('Fetch.enable', {
    #         handleAuthRequests: true,
    #         patterns: [{urlPattern: '*'}],
    #       }),
    #     ]);
    #   } else {
    #     await Promise.all([
    #       this._updateProtocolCacheDisabled(),
    #       this._client.send('Fetch.disable')
    #     ]);
    #   }
    # }

    # async _updateProtocolCacheDisabled() {
    #   await this._client.send('Network.setCacheDisabled', {
    #     cacheDisabled: this._userCacheDisabled || this._protocolRequestInterceptionEnabled
    #   });
    # }

    # /**
    #  * @param {!Protocol.Network.requestWillBeSentPayload} event
    #  */
    # _onRequestWillBeSent(event) {
    #   // Request interception doesn't happen for data URLs with Network Service.
    #   if (this._protocolRequestInterceptionEnabled && !event.request.url.startsWith('data:')) {
    #     const requestId = event.requestId;
    #     const interceptionId = this._requestIdToInterceptionId.get(requestId);
    #     if (interceptionId) {
    #       this._onRequest(event, interceptionId);
    #       this._requestIdToInterceptionId.delete(requestId);
    #     } else {
    #       this._requestIdToRequestWillBeSentEvent.set(event.requestId, event);
    #     }
    #     return;
    #   }
    #   this._onRequest(event, null);
    # }

    # /**
    #  * @param {!Protocol.Fetch.authRequiredPayload} event
    #  */
    # _onAuthRequired(event) {
    #   /** @type {"Default"|"CancelAuth"|"ProvideCredentials"} */
    #   let response = 'Default';
    #   if (this._attemptedAuthentications.has(event.requestId)) {
    #     response = 'CancelAuth';
    #   } else if (this._credentials) {
    #     response = 'ProvideCredentials';
    #     this._attemptedAuthentications.add(event.requestId);
    #   }
    #   const {username, password} = this._credentials || {username: undefined, password: undefined};
    #   this._client.send('Fetch.continueWithAuth', {
    #     requestId: event.requestId,
    #     authChallengeResponse: { response, username, password },
    #   }).catch(debugError);
    # }

    # /**
    #  * @param {!Protocol.Fetch.requestPausedPayload} event
    #  */
    # _onRequestPaused(event) {
    #   if (!this._userRequestInterceptionEnabled && this._protocolRequestInterceptionEnabled) {
    #     this._client.send('Fetch.continueRequest', {
    #       requestId: event.requestId
    #     }).catch(debugError);
    #   }

    #   const requestId = event.networkId;
    #   const interceptionId = event.requestId;
    #   if (requestId && this._requestIdToRequestWillBeSentEvent.has(requestId)) {
    #     const requestWillBeSentEvent = this._requestIdToRequestWillBeSentEvent.get(requestId);
    #     this._onRequest(requestWillBeSentEvent, interceptionId);
    #     this._requestIdToRequestWillBeSentEvent.delete(requestId);
    #   } else {
    #     this._requestIdToInterceptionId.set(requestId, interceptionId);
    #   }
    # }

    # /**
    #  * @param {!Protocol.Network.requestWillBeSentPayload} event
    #  * @param {?string} interceptionId
    #  */
    # _onRequest(event, interceptionId) {
    #   let redirectChain = [];
    #   if (event.redirectResponse) {
    #     const request = this._requestIdToRequest.get(event.requestId);
    #     // If we connect late to the target, we could have missed the requestWillBeSent event.
    #     if (request) {
    #       this._handleRequestRedirect(request, event.redirectResponse);
    #       redirectChain = request._redirectChain;
    #     }
    #   }
    #   const frame = event.frameId && this._frameManager ? this._frameManager.frame(event.frameId) : null;
    #   const request = new Request(this._client, frame, interceptionId, this._userRequestInterceptionEnabled, event, redirectChain);
    #   this._requestIdToRequest.set(event.requestId, request);
    #   this.emit(Events.NetworkManager.Request, request);
    # }

    # /**
    #  * @param {!Protocol.Network.requestServedFromCachePayload} event
    #  */
    # _onRequestServedFromCache(event) {
    #   const request = this._requestIdToRequest.get(event.requestId);
    #   if (request)
    #     request._fromMemoryCache = true;
    # }

    # /**
    #  * @param {!Request} request
    #  * @param {!Protocol.Network.Response} responsePayload
    #  */
    # _handleRequestRedirect(request, responsePayload) {
    #   const response = new Response(this._client, request, responsePayload);
    #   request._response = response;
    #   request._redirectChain.push(request);
    #   response._bodyLoadedPromiseFulfill.call(null, new Error('Response body is unavailable for redirect responses'));
    #   this._requestIdToRequest.delete(request._requestId);
    #   this._attemptedAuthentications.delete(request._interceptionId);
    #   this.emit(Events.NetworkManager.Response, response);
    #   this.emit(Events.NetworkManager.RequestFinished, request);
    # }

    # /**
    #  * @param {!Protocol.Network.responseReceivedPayload} event
    #  */
    # _onResponseReceived(event) {
    #   const request = this._requestIdToRequest.get(event.requestId);
    #   // FileUpload sends a response without a matching request.
    #   if (!request)
    #     return;
    #   const response = new Response(this._client, request, event.response);
    #   request._response = response;
    #   this.emit(Events.NetworkManager.Response, response);
    # }

    # /**
    #  * @param {!Protocol.Network.loadingFinishedPayload} event
    #  */
    # _onLoadingFinished(event) {
    #   const request = this._requestIdToRequest.get(event.requestId);
    #   // For certain requestIds we never receive requestWillBeSent event.
    #   // @see https://crbug.com/750469
    #   if (!request)
    #     return;

    #   // Under certain conditions we never get the Network.responseReceived
    #   // event from protocol. @see https://crbug.com/883475
    #   if (request.response())
    #     request.response()._bodyLoadedPromiseFulfill.call(null);
    #   this._requestIdToRequest.delete(request._requestId);
    #   this._attemptedAuthentications.delete(request._interceptionId);
    #   this.emit(Events.NetworkManager.RequestFinished, request);
    # }

    # /**
    #  * @param {!Protocol.Network.loadingFailedPayload} event
    #  */
    # _onLoadingFailed(event) {
    #   const request = this._requestIdToRequest.get(event.requestId);
    #   // For certain requestIds we never receive requestWillBeSent event.
    #   // @see https://crbug.com/750469
    #   if (!request)
    #     return;
    #   request._failureText = event.errorText;
    #   const response = request.response();
    #   if (response)
    #     response._bodyLoadedPromiseFulfill.call(null);
    #   this._requestIdToRequest.delete(request._requestId);
    #   this._attemptedAuthentications.delete(request._interceptionId);
    #   this.emit(Events.NetworkManager.RequestFailed, request);
    # }
  end
end