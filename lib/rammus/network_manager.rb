require 'rammus/request'
require 'rammus/response'

module Rammus
  class NetworkManager
    include EventEmitter
    include Promise::Await

    attr_reader :client, :frame_manager

    # @param [Rammus::CDPSession] client
    # @param [Rammus::FrameManager] frame_manager
    # @param [Boolean] ignore_https_errors
    #
    def initialize(client, frame_manager, ignore_https_errors)
      super()
      @client = client
      @frame_manager = frame_manager
      @_ignore_https_errors = ignore_https_errors
      # @type {!Map<string, !Request>}
      @_request_id_to_request = {}
      # @type {!Map<string, !Protocol.Network.requestWillBeSentPayload>}
      @_request_id_to_request_will_be_sent_event = {}
      # @type {!Object<string, string>}
      @_extra_http_headers = {}

      @_offline = false

      # @type {?{username: string, password: string}}
      @_credentials = nil
      # @type {!Set<string>}
      @_attempted_authentications = Set.new
      @_user_request_interception_enabled = false
      @_protocol_request_interception_enabled = false
      @_user_cache_disabled = false
      # @type {!Map<string, string>}
      @_request_id_to_interception_id = {}

      client.on Protocol::Fetch.request_paused, method(:on_request_paused)
      client.on Protocol::Fetch.auth_required, method(:on_auth_required)
      client.on Protocol::Network.request_will_be_sent, method(:on_request_will_be_sent)
      client.on Protocol::Network.request_served_from_cache, method(:on_request_served_from_cache)
      client.on Protocol::Network.response_received, method(:on_response_received)
      client.on Protocol::Network.loading_finished, method(:on_loading_finished)
      client.on Protocol::Network.loading_failed, method(:on_loading_failed)
    end

    def start
      await client.command Protocol::Network.enable
      if @_ignore_https_errors
        await client.command Protocol::Security.set_ignore_certificate_errors ignore: true
      end
    end

    # @param {?{username: string, password: string}} credentials
    #
    def authenticate(username: nil, password: nil)
       @_credentials = { username: username, password: password }
       update_protocol_request_interception
    end

    # @param {!Object<string, string>} extraHTTPHeaders
    #
    def set_extra_http_headers(extra_http_headers)
      @_extra_http_headers = extra_http_headers.map do |key, value|
        raise "Expected value of header '#{key}' to be String, but '#{value.class}' is found." unless value.is_a? String
        [key.downcase, value]
      end.to_h
      await client.command Protocol::Network.set_extra_http_headers headers: @_extra_http_headers
    end

    # @return {!Object<string, string>}
    #
    def extra_http_headers
      @_extra_http_headers.dup
    end

    # @param {boolean} value
    #
    def set_offline_mode(value)
      return if @_offline == value
      @_offline = value

      # values of 0 remove any active throttling. crbug.com/456324#c9
      await client.command Protocol::Network.emulate_network_conditions offline: @_offline, latency: 0, download_throughput: -1, upload_throughput: -1
    end

    # @param [String] user_agent
    #
    def set_user_agent(user_agent)
      await client.command Protocol::Network.set_user_agent_override user_agent: user_agent
    end

    # @param {boolean} enabled
    #
    def set_cache_enabled(enabled)
      @_user_cache_disabled = !enabled
      update_protocol_cache_disabled
    end

    # @param {boolean} value
    #
    def set_request_interception(value)
      @_user_request_interception_enabled = value
      update_protocol_request_interception
    end

    private

      # @param {!Protocol.Network.requestWillBeSentPayload} event
      #
      def on_request_will_be_sent(event)
        # Request interception doesn't happen for data URLs with Network Service.
        if @_protocol_request_interception_enabled && !event.dig("request", "url").start_with?('data:')
          request_id = event["requestId"]
          interception_id = @_request_id_to_interception_id[request_id]

          if interception_id
            on_request event, interception_id
            @_request_id_to_interception_id.delete request_id
          else
            @_request_id_to_request_will_be_sent_event[event["requestId"]]= event
          end
          return
        end
        on_request event, nil
      end

      # @param {!Protocol.Network.requestWillBeSentPayload} event
      # @param {?string} interceptionId
      #
      def on_request(event, interception_id)
        redirect_chain = []
        if event["redirectResponse"]
          request = @_request_id_to_request[event["requestId"]]
          # If we connect late to the target, we could have missed the requestWillBeSent event.
          if request
            handle_request_redirect request, event["redirectResponse"]
            redirect_chain = request.redirect_chain
          end
        end
        frame = event["frameId"] && frame_manager ? frame_manager.frame(event["frameId"]) : nil
        request = Request.new client, frame, interception_id, @_user_request_interception_enabled, event, redirect_chain
        @_request_id_to_request[event["requestId"]] = request
        emit :request, request
      end

      # @param {!Protocol.Network.responseReceivedPayload} event
      #
      def on_response_received(event)
        request = @_request_id_to_request[event["requestId"]]
        # FileUpload sends a response without a matching request.
        return if request.nil?
        response = Response.new client, request, event["response"]
        request.response = response
        emit :response, response
      end

      # @param {!Protocol.Network.loadingFinishedPayload} event
      #
      def on_loading_finished(event)
        request = @_request_id_to_request[event["requestId"]]
        # For certain requestIds we never receive requestWillBeSent event.
        # @see https://crbug.com/750469
        return if request.nil?

        # Under certain conditions we never get the Network.responseReceived
        # event from protocol. @see https://crbug.com/883475
        unless request.response.nil?
          request.response.body_loaded_promise_fulfill.call(nil)
        end
        @_request_id_to_request.delete(request.request_id)
        @_attempted_authentications.delete request.interception_id
        emit :request_finished, request
      end

      # @param {!Protocol.Network.requestServedFromCachePayload} event
      #
      def on_request_served_from_cache(event)
        request = @_request_id_to_request[event["requestId"]]
        request.from_memory_cache = true if request
      end

      # @param {!Request} request
      # @param {!Protocol.Network.Response} responsePayload
      #
      def handle_request_redirect(request, response_payload)
        response = Response.new client, request, response_payload
        request.response = response
        request.redirect_chain << request

        response.body_loaded_promise_fulfill.(StandardError.new 'Response body is unavailable for redirect responses')
        @_request_id_to_request.delete(request.request_id)
        @_attempted_authentications.delete request.interception_id
        emit :response, response
        emit :request_finished, request
      end

      def update_protocol_cache_disabled
        client.command Protocol::Network.set_cache_disabled(
          cache_disabled: @_user_cache_disabled || @_protocol_request_interception_enabled
        )
      end

      def update_protocol_request_interception
        enabled = @_user_request_interception_enabled || !!@_credentials

        return if enabled == @_protocol_request_interception_enabled

        @_protocol_request_interception_enabled = enabled
        if enabled
          await Promise.all(
            update_protocol_cache_disabled,
            client.command(Protocol::Fetch.enable(handle_auth_requests: true, patterns: [urlPattern: '*']))
          )
        else
          await Promise.all(
            update_protocol_cache_disabled,
            client.command(Protocol::Fetch.disable)
          )
        end
      end

      # @param {!Protocol.Fetch.requestPausedPayload} event
      #
      def on_request_paused(event)
        if !@_user_request_interception_enabled && @_protocol_request_interception_enabled
          client.command(Protocol::Fetch.continue_request(request_id: event["requestId"]))
            .catch { |error| Util.debug_error error }
        end

        request_id = event["networkId"]
        interception_id = event["requestId"]

        if request_id && @_request_id_to_request_will_be_sent_event.include?(request_id)
          request_will_be_sent_event = @_request_id_to_request_will_be_sent_event[request_id]
          on_request request_will_be_sent_event, interception_id
          @_request_id_to_request_will_be_sent_event.delete request_id
        else
          @_request_id_to_interception_id[request_id] = interception_id
        end
      end

      # @param {!Protocol.Fetch.authRequiredPayload} event
      #
      def on_auth_required(event)
        # @type {"Default"|"CancelAuth"|"ProvideCredentials"}
        response = 'Default'
        if @_attempted_authentications.include? event["requestId"]
          response = 'CancelAuth'
        elsif @_credentials
          response = 'ProvideCredentials'
          @_attempted_authentications.add event["requestId"]
        end

        username ||= @_credentials[:username]
        password ||= @_credentials[:password]
        client.command(Protocol::Fetch.continue_with_auth(
          request_id: event["requestId"],
          auth_challenge_response: { response: response, username: username, password: password }.compact
        )).catch { |error| Util.debug_error error }
      end

      # @param {!Protocol.Network.loadingFailedPayload} event
      #
      def on_loading_failed(event)
        request = @_request_id_to_request[event["requestId"]]
        # For certain requestIds we never receive requestWillBeSent event.
        # @see https://crbug.com/750469
        return if request.nil?
        request.failure_text = event["errorText"]
        response = request.response
        response.body_loaded_promise_fulfill.(nil) if response
        @_request_id_to_request.delete request.request_id
        @_attempted_authentications.delete request.interception_id
        emit :request_failed, request
      end
  end
end
