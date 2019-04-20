module Chromiebara
  module Protocol
    module Network
      extend self

      # Tells whether clearing browser cache is supported.
      # 
      #
      def can_clear_browser_cache
        {
          method: "Network.canClearBrowserCache"
        }
      end

      # Tells whether clearing browser cookies is supported.
      # 
      #
      def can_clear_browser_cookies
        {
          method: "Network.canClearBrowserCookies"
        }
      end

      # Tells whether emulation of network conditions is supported.
      # 
      #
      def can_emulate_network_conditions
        {
          method: "Network.canEmulateNetworkConditions"
        }
      end

      # Clears browser cache.
      # 
      #
      def clear_browser_cache
        {
          method: "Network.clearBrowserCache"
        }
      end

      # Clears browser cookies.
      # 
      #
      def clear_browser_cookies
        {
          method: "Network.clearBrowserCookies"
        }
      end

      # Response to Network.requestIntercepted which either modifies the request to continue with any
      # modifications, or blocks it, or completes it with the provided response bytes. If a network
      # fetch occurs as a result which encounters a redirect an additional Network.requestIntercepted
      # event will be sent with the same InterceptionId.
      # 
      # @param error_reason [Errorreason] If set this causes the request to fail with the given reason. Passing `Aborted` for requests marked with `isNavigationRequest` also cancels the navigation. Must not be set in response to an authChallenge.
      # @param raw_response [Binary] If set the requests completes using with the provided base64 encoded raw response, including HTTP status line and headers etc... Must not be set in response to an authChallenge.
      # @param url [String] If set the request url will be modified in a way that's not observable by page. Must not be set in response to an authChallenge.
      # @param method [String] If set this allows the request method to be overridden. Must not be set in response to an authChallenge.
      # @param post_data [String] If set this allows postData to be set. Must not be set in response to an authChallenge.
      # @param headers [Headers] If set this allows the request headers to be changed. Must not be set in response to an authChallenge.
      # @param auth_challenge_response [Authchallengeresponse] Response to a requestIntercepted with an authChallenge. Must not be set otherwise.
      #
      def continue_intercepted_request(interception_id:, error_reason: nil, raw_response: nil, url: nil, method: nil, post_data: nil, headers: nil, auth_challenge_response: nil)
        {
          method: "Network.continueInterceptedRequest",
          params: { interceptionId: interception_id, errorReason: error_reason, rawResponse: raw_response, url: url, method: method, postData: post_data, headers: headers, authChallengeResponse: auth_challenge_response }.compact
        }
      end

      # Deletes browser cookies with matching name and url or domain/path pair.
      # 
      # @param name [String] Name of the cookies to remove.
      # @param url [String] If specified, deletes all the cookies with the given name where domain and path match provided URL.
      # @param domain [String] If specified, deletes only cookies with the exact domain.
      # @param path [String] If specified, deletes only cookies with the exact path.
      #
      def delete_cookies(name:, url: nil, domain: nil, path: nil)
        {
          method: "Network.deleteCookies",
          params: { name: name, url: url, domain: domain, path: path }.compact
        }
      end

      # Disables network tracking, prevents network events from being sent to the client.
      # 
      #
      def disable
        {
          method: "Network.disable"
        }
      end

      # Activates emulation of network conditions.
      # 
      # @param offline [Boolean] True to emulate internet disconnection.
      # @param latency [Number] Minimum latency from request sent to response headers received (ms).
      # @param download_throughput [Number] Maximal aggregated download throughput (bytes/sec). -1 disables download throttling.
      # @param upload_throughput [Number] Maximal aggregated upload throughput (bytes/sec). -1 disables upload throttling.
      # @param connection_type [Connectiontype] Connection type if known.
      #
      def emulate_network_conditions(offline:, latency:, download_throughput:, upload_throughput:, connection_type: nil)
        {
          method: "Network.emulateNetworkConditions",
          params: { offline: offline, latency: latency, downloadThroughput: download_throughput, uploadThroughput: upload_throughput, connectionType: connection_type }.compact
        }
      end

      # Enables network tracking, network events will now be delivered to the client.
      # 
      # @param max_total_buffer_size [Integer] Buffer size in bytes to use when preserving network payloads (XHRs, etc).
      # @param max_resource_buffer_size [Integer] Per-resource buffer size in bytes to use when preserving network payloads (XHRs, etc).
      # @param max_post_data_size [Integer] Longest post body size (in bytes) that would be included in requestWillBeSent notification
      #
      def enable(max_total_buffer_size: nil, max_resource_buffer_size: nil, max_post_data_size: nil)
        {
          method: "Network.enable",
          params: { maxTotalBufferSize: max_total_buffer_size, maxResourceBufferSize: max_resource_buffer_size, maxPostDataSize: max_post_data_size }.compact
        }
      end

      # Returns all browser cookies. Depending on the backend support, will return detailed cookie
      # information in the `cookies` field.
      # 
      #
      def get_all_cookies
        {
          method: "Network.getAllCookies"
        }
      end

      # Returns the DER-encoded certificate.
      # 
      # @param origin [String] Origin to get certificate for.
      #
      def get_certificate(origin:)
        {
          method: "Network.getCertificate",
          params: { origin: origin }.compact
        }
      end

      # Returns all browser cookies for the current URL. Depending on the backend support, will return
      # detailed cookie information in the `cookies` field.
      # 
      # @param urls [Array] The list of URLs for which applicable cookies will be fetched
      #
      def get_cookies(urls: nil)
        {
          method: "Network.getCookies",
          params: { urls: urls }.compact
        }
      end

      # Returns content served for the given request.
      # 
      # @param request_id [Requestid] Identifier of the network request to get content for.
      #
      def get_response_body(request_id:)
        {
          method: "Network.getResponseBody",
          params: { requestId: request_id }.compact
        }
      end

      # Returns post data sent with the request. Returns an error when no data was sent with the request.
      # 
      # @param request_id [Requestid] Identifier of the network request to get content for.
      #
      def get_request_post_data(request_id:)
        {
          method: "Network.getRequestPostData",
          params: { requestId: request_id }.compact
        }
      end

      # Returns content served for the given currently intercepted request.
      # 
      # @param interception_id [Interceptionid] Identifier for the intercepted request to get body for.
      #
      def get_response_body_for_interception(interception_id:)
        {
          method: "Network.getResponseBodyForInterception",
          params: { interceptionId: interception_id }.compact
        }
      end

      # Returns a handle to the stream representing the response body. Note that after this command,
      # the intercepted request can't be continued as is -- you either need to cancel it or to provide
      # the response body. The stream only supports sequential read, IO.read will fail if the position
      # is specified.
      # 
      #
      def take_response_body_for_interception_as_stream(interception_id:)
        {
          method: "Network.takeResponseBodyForInterceptionAsStream",
          params: { interceptionId: interception_id }.compact
        }
      end

      # This method sends a new XMLHttpRequest which is identical to the original one. The following
      # parameters should be identical: method, url, async, request body, extra headers, withCredentials
      # attribute, user, password.
      # 
      # @param request_id [Requestid] Identifier of XHR to replay.
      #
      def replay_xhr(request_id:)
        {
          method: "Network.replayXHR",
          params: { requestId: request_id }.compact
        }
      end

      # Searches for given string in response content.
      # 
      # @param request_id [Requestid] Identifier of the network response to search.
      # @param query [String] String to search for.
      # @param case_sensitive [Boolean] If true, search is case sensitive.
      # @param is_regex [Boolean] If true, treats string parameter as regex.
      #
      def search_in_response_body(request_id:, query:, case_sensitive: nil, is_regex: nil)
        {
          method: "Network.searchInResponseBody",
          params: { requestId: request_id, query: query, caseSensitive: case_sensitive, isRegex: is_regex }.compact
        }
      end

      # Blocks URLs from loading.
      # 
      # @param urls [Array] URL patterns to block. Wildcards ('*') are allowed.
      #
      def set_blocked_ur_ls(urls:)
        {
          method: "Network.setBlockedURLs",
          params: { urls: urls }.compact
        }
      end

      # Toggles ignoring of service worker for each request.
      # 
      # @param bypass [Boolean] Bypass service worker and load from network.
      #
      def set_bypass_service_worker(bypass:)
        {
          method: "Network.setBypassServiceWorker",
          params: { bypass: bypass }.compact
        }
      end

      # Toggles ignoring cache for each request. If `true`, cache will not be used.
      # 
      # @param cache_disabled [Boolean] Cache disabled state.
      #
      def set_cache_disabled(cache_disabled:)
        {
          method: "Network.setCacheDisabled",
          params: { cacheDisabled: cache_disabled }.compact
        }
      end

      # Sets a cookie with the given cookie data; may overwrite equivalent cookies if they exist.
      # 
      # @param name [String] Cookie name.
      # @param value [String] Cookie value.
      # @param url [String] The request-URI to associate with the setting of the cookie. This value can affect the default domain and path values of the created cookie.
      # @param domain [String] Cookie domain.
      # @param path [String] Cookie path.
      # @param secure [Boolean] True if cookie is secure.
      # @param http_only [Boolean] True if cookie is http-only.
      # @param same_site [Cookiesamesite] Cookie SameSite type.
      # @param expires [Timesinceepoch] Cookie expiration date, session cookie if not set
      #
      def set_cookie(name:, value:, url: nil, domain: nil, path: nil, secure: nil, http_only: nil, same_site: nil, expires: nil)
        {
          method: "Network.setCookie",
          params: { name: name, value: value, url: url, domain: domain, path: path, secure: secure, httpOnly: http_only, sameSite: same_site, expires: expires }.compact
        }
      end

      # Sets given cookies.
      # 
      # @param cookies [Array] Cookies to be set.
      #
      def set_cookies(cookies:)
        {
          method: "Network.setCookies",
          params: { cookies: cookies }.compact
        }
      end

      # For testing.
      # 
      # @param max_total_size [Integer] Maximum total buffer size.
      # @param max_resource_size [Integer] Maximum per-resource size.
      #
      def set_data_size_limits_for_test(max_total_size:, max_resource_size:)
        {
          method: "Network.setDataSizeLimitsForTest",
          params: { maxTotalSize: max_total_size, maxResourceSize: max_resource_size }.compact
        }
      end

      # Specifies whether to always send extra HTTP headers with the requests from this page.
      # 
      # @param headers [Headers] Map with extra HTTP headers.
      #
      def set_extra_http_headers(headers:)
        {
          method: "Network.setExtraHTTPHeaders",
          params: { headers: headers }.compact
        }
      end

      # Sets the requests to intercept that match a the provided patterns and optionally resource types.
      # 
      # @param patterns [Array] Requests matching any of these patterns will be forwarded and wait for the corresponding continueInterceptedRequest call.
      #
      def set_request_interception(patterns:)
        {
          method: "Network.setRequestInterception",
          params: { patterns: patterns }.compact
        }
      end

      # Allows overriding user agent with the given string.
      # 
      # @param user_agent [String] User agent to use.
      # @param accept_language [String] Browser langugage to emulate.
      # @param platform [String] The platform navigator.platform should return.
      #
      def set_user_agent_override(user_agent:, accept_language: nil, platform: nil)
        {
          method: "Network.setUserAgentOverride",
          params: { userAgent: user_agent, acceptLanguage: accept_language, platform: platform }.compact
        }
      end
    end
  end
end
