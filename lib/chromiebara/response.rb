module Chromiebara
  class Response
    include Promise::Await

    attr_reader :client, :request, :url, :status, :status_text, :from_service_worker, :body_loaded_promise_fulfill,
      :remote_address

    def initialize(client, request, response_payload)
      @client = client
      @request = request
      #this._contentPromise = null;

      @_body_loaded_promise, @body_loaded_promise_fulfill, _ = Promise.create

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
      #this._securityDetails = responsePayload.securityDetails ? new SecurityDetails(responsePayload.securityDetails) : null;
    end

    # @return {boolean}
    #
    def ok?
      status == 0 || status >= 200 && status <= 299
    end

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

    def buffer
      @_buffer ||= await(@_body_loaded_promise.then do |error|
        raise error if error

        response = await client.command Protocol::Network.get_response_body(request_id: request.request_id)
        if response["base64Encoded"]
          Base64.decode64 response["body"]
        else
          response["body"]
        end
      end)
    end

    def text
      buffer
    end

    def json
      JSON.parse(text)
    end

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
