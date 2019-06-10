module Chromiebara
  class Response
    attr_reader :client, :request, :url, :status, :from_service_worker

    def initialize(client, request, response_payload)
      @client = client
      @request = request
      #this._contentPromise = null;

      #this._bodyLoadedPromise = new Promise(fulfill => {
      #  this._bodyLoadedPromiseFulfill = fulfill;
      #});

      #this._remoteAddress = {
      #  ip: responsePayload.remoteIPAddress,
      #  port: responsePayload.remotePort,
      #};
      @status = response_payload["status"]
      #this._statusText = responsePayload.statusText;
      @url = request.url
      @_from_disk_cache = !!response_payload["fromDiskCache"]
      @from_service_worker = !!response_payload["fromServiceWorker"]
      @_headers = response_payload.fetch("headers", {}).map do |name, value|
        [name.downcase, value]
      end.to_h
      #this._securityDetails = responsePayload.securityDetails ? new SecurityDetails(responsePayload.securityDetails) : null;
    end

    # * @return {{ip: string, port: number}}
    # */
    #remoteAddress() {
    #  return this._remoteAddress;
    #}

    # * @return {boolean}
    # */
    #ok() {
    #  return this._status === 0 || (this._status >= 200 && this._status <= 299);
    #}

    # * @return {string}
    # */
    #statusText() {
    #  return this._statusText;
    #}

    # @return {!Object}
    #
    def headers
      @_headers.dup
    end

    # * @return {?SecurityDetails}
    # */
    #securityDetails() {
    #  return this._securityDetails;
    #}

    # * @return {!Promise<!Buffer>}
    # */
    #buffer() {
    #  if (!this._contentPromise) {
    #    this._contentPromise = this._bodyLoadedPromise.then(async error => {
    #      if (error)
    #        throw error;
    #      const response = await this._client.send('Network.getResponseBody', {
    #        requestId: this._request._requestId
    #      });
    #      return Buffer.from(response.body, response.base64Encoded ? 'base64' : 'utf8');
    #    });
    #  }
    #  return this._contentPromise;
    #}

    # * @return {!Promise<string>}
    # */
    #async text() {
    #  const content = await this.buffer();
    #  return content.toString('utf8');
    #}

    # * @return {!Promise<!Object>}
    # */
    #async json() {
    #  const content = await this.text();
    #  return JSON.parse(content);
    #}

    # @return [Boolean]
    #
    def from_cache
      @_from_disk_cache || request.from_memory_cache
    end

    # * @return {boolean}
    # */
    #fromServiceWorker() {
    #  return this._fromServiceWorker;
    #}

    # * @return {?Puppeteer.Frame}
    # */
    #frame() {
    #  return this._request.frame();
    #}
  end
end
