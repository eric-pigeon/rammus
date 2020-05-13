# frozen_string_literal: true

module Rammus
  # At every point of time, page exposes its current frame tree via the
  # {Page#main_frame} and {Frame#child_frames} methods.
  #
  # Frame object's lifecycle is controlled by three events, dispatched on the page object:
  #
  # * frameattached - fired when the frame gets attached to the page. A Frame can be attached to the page only once.
  # * framenavigated - fired when the frame commits navigation to a different URL.
  # * framedetached - fired when the frame gets detached from the page. A Frame can be detached from the page only once.
  #
  class Frame
    extend Forwardable
    # @!visibility private
    #
    attr_reader :id, :frame_manager, :loader_id, :main_world, :secondary_world

    # The frame's parent frame if any.  Detached Frames and main frames return
    # nil.
    #
    # @return [Rammus::Frame, nil]
    #
    attr_reader :parent_frame

    # @!method query_selector(selector)
    #   (see Rammus::DOMWorld#query_selector)
    #
    # @!method query_selector_all(selector)
    #    (see Rammus::DOMWorld#query_selector_all)
    #
    # @!method query_selector_all_evaluate_function(selector, page_function, *args)
    #    (see Rammus::DOMWorld#query_selector_all_evaluate_function)
    #
    # @!method query_selector_evaluate_function(selector, page_function, *args)
    #    (see Rammus::DOMWorld#query_selector_evaluate_function)
    #
    # @!method xpath(expression)
    #    (see Rammus::DOMWorld#xpath)
    #
    # @!method add_script_tag(url: nil, path: nil, content: nil, type: '' )
    #    (see Rammus::DOMWorld#add_script_tag)
    #
    # @!method add_style_tag(url: nil, path: nil, content: nil)
    #    (see Rammus::DOMWorld#add_style_tag)
    #
    # @!method evaluate(javascript)
    #    (see Rammus::DOMWorld#evaluate)
    #
    # @!method evaluate_function(page_function, *args)
    #    (see Rammus::DOMWorld#evaluate_function)
    #
    # @!method evaluate_handle(javascript)
    #    (see Rammus::DOMWorld#evaluate_handle)
    #
    # @!method evaluate_handle_function(page_function, *args)
    #    (see Rammus::DOMWorld#evaluate_handle_function)
    #
    # @!method execution_context
    #    (see Rammus::DOMWorld#execution_context)
    #
    # @!method wait_for_function(page_function, *args, polling: 'raf', timeout: nil)
    #    (see Rammus::DOMWorld#wait_for_function)
    #
    delegate [
      :add_script_tag,
      :add_style_tag,
      :evaluate,
      :evaluate_function,
      :evaluate_handle,
      :evaluate_handle_function,
      :execution_context,
      :query_selector,
      :query_selector_all,
      :query_selector_all_evaluate_function,
      :query_selector_evaluate_function,
      :wait_for_function,
      :xpath
    ] => :main_world

    # @!method click(selector, button: Mouse::Button::LEFT, click_count: 1, delay: 0)
    #   (see Rammus::DOMWorld#click)
    #
    # @!method focus(selector)
    #   (see Rammus::DOMWorld#focus)
    #
    # @!method hover(selector)
    #   (see Rammus::DOMWorld#hover)
    #
    # @!method select(selector, *values)
    #   (see Rammus::DOMWorld#select)
    #
    # @!method touchscreen_tap(selector)
    #   (see Rammus::DOMWorld#touchscreen_tap)
    #
    # @!method title
    #   (see Rammus::DOMWorld#title)
    #
    # @!method type(selector, text, delay: nil)
    #   (see Rammus::DOMWorld#type)
    #
    delegate [
      :click,
      :focus,
      :hover,
      :select,
      :touchscreen_tap,
      :title,
      :type
    ] => :secondary_world

    # @!visibility private
    #
    # @param frame_manager [Rammus::FrameManager]
    # @param client [Rammus::CPDSession]
    # @param parent_frame [Rammus::Frame, nil]
    # @param id [Integer]
    #
    def initialize(frame_manager, client, parent_frame, id)
      @frame_manager = frame_manager
      @client = client
      @parent_frame = parent_frame
      @_url = ''
      @id = id
      @_detached = false
      @_name = nil

      @loader_id = ''
      # @type {!Set<string>}
      @_lifecycle_events = Set.new
      # @type {!DOMWorld}
      @main_world = DOMWorld.new frame_manager, self, frame_manager.timeout_settings
      # @type {!DOMWorld}
      @secondary_world = DOMWorld.new frame_manager, self, frame_manager.timeout_settings

      # @type {!Set<!Frame>}
      @child_frames = Set.new
      # TODO
      parent_frame&.instance_variable_get(:@child_frames)&.add self
    end

    # {goto} will throw an error if:
    # * there's an SSL error (e.g. in case of self-signed certificates).
    # * target URL is invalid.
    # * the timeout is exceeded during navigation.
    # * the remote server does not respond or is unreachable.
    # * the main resource failed to load.
    #
    # {goto} will not throw an error when any valid HTTP status code is
    # returned by the remote server, including 404 "Not Found" and 500
    # "Internal Server Error". The status code for such responses can be
    # retrieved by calling {Network::Response#status}.
    #
    # @note {goto} either throws an error or returns a main resource response.
    #   The only exceptions are navigation to about:blank or navigation to the
    #   same URL with a different hash, which would succeed and return null.
    #
    # @param url [String] URL to navigate frame to. The url should include scheme, e.g. https://.
    # @param timeout [Integer] Maximum navigation time in seconds, defaults to
    #   2 seconds, pass 0 to disable timeout. The default value can be changed
    #   by using the {Page#set_default_navigation_timeout} or
    #   {Page#set_default_timeout} methods.
    # @param wait_until [Array<Symbol>, Symbol] When to consider navigation
    #   succeeded, defaults to load. Given an array of event strings, navigation
    #   is considered to be successful after all events have been fired. Event
    #   can be either:
    #   * :load - consider navigation to be finished when the load event is fired.
    #   * :domcontentloaded - consider navigation to be finished when the DOMContentLoaded event is fired.
    #   * :networkidle0 - consider navigation to be finished when there are no more than 0 network connections for at least 500 ms.
    #   * :networkidle2 - consider navigation to be finished when there are no more than 2 network connections for at least 500 ms.
    # @param referer [String] Referer header value. If provided it will take
    #   preference over the referer header value set by {Page#set_extra_http_headers}
    #
    # @return [Promise<Response, nil>] Promise which resolves to the main
    #   resource response. In case of multiple redirects, the navigation will
    #   resolve with the response of the last redirect.
    #
    def goto(url, referer: nil, timeout: nil, wait_until: nil)
      frame_manager.navigate_frame self, url, referer: referer, timeout: timeout, wait_until: wait_until
    end

    # This resolves when the frame navigates to a new URL. It is useful for
    # when you run code which will indirectly cause the frame to navigate.
    #
    # @example
    #   response, _ = await Rammus::Promise.all(
    #     frame.wait_for_navigation, # The navigation promise resolves after navigation has finished
    #     frame.click('a.my-link') # Clicking the link will indirectly cause a navigation
    #   )
    # @note Usage of the History API to change the URL is considered a navigation.
    #
    # @param timeout [Integer] Maximum navigation time in seconds, defaults to
    #   2 seconds, pass 0 to disable timeout. The default value can be changed
    #   by using the {Page#set_default_navigation_timeout} or
    #   {Page#set_default_timeout} methods.
    # @param wait_until [Array<Symbol>, Symbol] When to consider navigation
    #   succeeded, defaults to load. Given an array of event strings,
    #   navigation is considered to be successful after all events have been
    #   fired. Events can be either:
    #   * :load - consider navigation to be finished when the load event is fired.
    #   * :domcontentloaded - consider navigation to be finished when the DOMContentLoaded event is fired.
    #   * :networkidle0 - consider navigation to be finished when there are no more than 0 network connections for at least 500 ms.
    #   * :networkidle2 - consider navigation to be finished when there are no more than 2 network connections for at least 500 ms.
    #
    # @return [Promise<Rammus::Response, nil>] Promise which resolves to the
    #   main resource response. In case of multiple redirects, the navigation
    #   will resolve with the response of the last redirect. In case of
    #   navigation to a different anchor or navigation due to History API usage,
    #   the navigation will resolve with nil.
    #
    def wait_for_navigation(timeout: nil, wait_until: nil)
      frame_manager.wait_for_frame_navigation self, timeout: timeout, wait_until: wait_until
    end

    # (see Rammus::DOMWorld#content)
    #
    def content
      secondary_world.content
    end

    # (see Rammus::DOMWorld#set_content)
    #
    def set_content(html, timeout: nil, wait_until: nil)
      secondary_world.set_content html, timeout: timeout, wait_until: wait_until
    end

    # Returns frame's name attribute as specified in the tag.
    #
    # @note This value is calculated once when the frame is created, and will
    #   not update if the attribute is changed later.
    #
    # @return [String]
    #
    def name
      @_name || ''
    end

    # Frame's URL
    #
    # @return [String]
    #
    def url
      @_url
    end

    # The frame's child frames
    #
    # @return [Array<Frame>]
    #
    def child_frames
      @child_frames.to_a
    end

    # Returns true if the frame has been detached, or false otherwise.
    #
    # @return [Boolean]
    #
    def is_detached?
      @_detached
    end

    # Wait for the selector to appear in page. If at the moment of calling th
    # method the selector already exists, the method will return immediately.
    # If the selector doesn't appear after the timeout seconds of waiting, the
    # function will throw.
    #
    # TODO verify this
    # @example waiting across navigations
    #   page = browser.new_page
    #   current_url = nil
    #   page.main_frame
    #     .wait_for_selector('img')
    #     .then { puts "First URL with image: #{current_url}" }
    #   ['https://example.com', 'https://google.com', 'https://bbc.com'].each do |url|
    #     current_url = url
    #     await page.goto current_url
    #   end
    #
    # @param selector [String] A selector of an element to wait for
    # @param visible [Boolean] wait for element to be present in DOM and to be
    #   visible, i.e. to not have display: none or visibility: hidden CSS
    #   properties. Defaults to false.
    # @param hidden [Boolean] wait for element to not be found in the DOM or to
    #   be hidden, i.e. have display: none or visibility: hidden CSS properties.
    #   Defaults to false.
    # @param timeout [Integer] maximum time to wait for in seconds. Defaults to
    #   2 seconds . Pass 0 to disable timeout. The default value can be changed
    #   by using the {Rammus::Page#set_default_timeout} method.
    #
    # @return [Promise<ElementHandle>] Promise which resolves when element
    #   specified by selector string is added to DOM. Resolves to null if
    #   waiting for hidden: true and selector is not found in DOM.
    #
    def wait_for_selector(selector, visible: nil, hidden: nil, timeout: nil)
      secondary_world.wait_for_selector(selector, visible: visible, hidden: hidden, timeout: timeout).then do |handle|
        next nil if handle.nil?

        main_execution_context = main_world.execution_context
        result = main_execution_context._adopt_element_handle handle
        handle.dispose
        result
      end
    end

    # Wait for the xpath to appear in page. If at the moment of calling the
    # method the xpath already exists, the method will return immediately. If
    # the xpath doesn't appear after the timeout seconds of waiting, the
    # function will throw.
    #
    # # TODO verify this
    # @example waiting across navigation
    #   page = browser.new_page
    #   current_url = nil
    #   page.main_frame
    #     .wait_for_xpath('//img')
    #     .then { puts "First URL with image: #{current_url}" }
    #   ['https://example.com', 'https://google.com', 'https://bbc.com'].each do |url|
    #     current_url = url
    #     await page.goto current_url
    #   end
    #
    # @param xpath [String] A xpath of an element to wait for
    # @param visible [Boolean] wait for element to be present in DOM and to be
    #   visible, i.e. to not have display: none or visibility: hidden CSS
    #   properties. Defaults to false.
    # @param hidden [Boolean] wait for element to not be found in the DOM or to
    #   be hidden, i.e. have display: none or visibility: hidden CSS properties.
    #   Defaults to false.
    # @param timeout [Integer] maximum time to wait for in seconds. Defaults to
    #   2 seconds . Pass 0 to disable timeout. The default value can be changed
    #   by using the {Page.set_default_timeout} method.
    #
    # @return [Promise<ElementHandle>] Promise which resolves when element
    #   specified by xpath string is added to DOM. Resolves to null if waiting
    #   for hidden: true and xpath is not found in DOM.
    #
    def wait_for_xpath(xpath, visible: nil, hidden: nil, timeout: nil)
      secondary_world.wait_for_xpath(xpath, visible: visible, hidden: hidden, timeout: timeout).then do |handle|
        next if handle.nil?

        result = main_world.execution_context._adopt_element_handle handle
        handle.dispose
        result
      end
    end

    # @!visibility private
    #
    def _detach
      @_detached = true
      main_world._detach
      secondary_world._detach
      # TODO
      parent_frame&.instance_variable_get(:@child_frames)&.delete self
      @parent_frame = nil
    end

    # @!visibility private
    #
    # @param url [String]
    #
    def _navigated_within_document(url)
      @_url = url
    end

    # @!visibility private
    #
    def lifecycle_events
      @_lifecycle_events.dup
    end

    private

      # @param [Hash] frame_payload Protocol.Page.Frame
      #
      def navigated(frame_payload)
        @_name = frame_payload["name"]
        @_url = frame_payload["url"]
      end

      # @param [String] loader_id
      # @param [String] name
      #
      def on_lifecycle_event(loader_id, name)
        if name == "init"
          @loader_id = loader_id
          @_lifecycle_events.clear
        end

        @_lifecycle_events.add name
      end

      def on_loading_stopped
        @_lifecycle_events.add 'DOMContentLoaded'
        @_lifecycle_events.add 'load'
      end
  end
end
