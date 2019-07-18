module Chromiebara
  class Frame
    extend Forwardable
    include Promise::Await

    attr_reader :id, :frame_manager, :parent_frame, :loader_id, :main_world, :secondary_world

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

    delegate [
      :focus,
      :hover,
      :select,
      :touchscreen_tap,
      :title,
      :type
    ] => :secondary_world

    # @param [Chromiebara::FrameManager] frame_manager
    # @param [Chromiebara::CPDSession] client
    # @param [Chromiebara::Frame, nil] parent_frame
    # @param [Integer] id
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
      @main_world =  DOMWorld.new frame_manager, self, frame_manager.timeout_settings
      # @type {!DOMWorld}
      @secondary_world = DOMWorld.new frame_manager, self, frame_manager.timeout_settings

      # @type {!Set<!Frame>}
      @child_frames = Set.new
      if parent_frame
        # TODO
        parent_frame.instance_variable_get(:@child_frames).add self
      end
    end

    # TODO
    #
    def lifecycle_events
      @_lifecycle_events.dup
    end

    # @param [String] url
    #
    def goto(url, referer: nil, timeout: nil, wait_until: nil)
      frame_manager.navigate_frame self, url, referer: referer, timeout: timeout, wait_until: wait_until
    end

    # @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
    # @return {!Promise<?Puppeteer.Response>}
    #
    def wait_for_navigation(timeout: nil, wait_until: nil)
      frame_manager.wait_for_frame_navigation self, timeout: timeout, wait_until: wait_until
    end

    #  @return {!Promise<String>}
    #
    def content
      return secondary_world.content
    end

    # @param {string} html
    # @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
    #
    def set_content(html, timeout: nil, wait_until: nil)
      secondary_world.set_content html, timeout: timeout, wait_until: wait_until
    end

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

    # @return {!Array.<!Frame>}
    #
    def child_frames
      @child_frames.to_a
    end

    # @return {boolean}
    #
    def is_detached?
      @_detached
    end

    # @param {string} selector
    # @param {!{delay?: number, button?: "left"|"right"|"middle", clickCount?: number}=} options
    #
    def click(selector, options = {})
      secondary_world.click selector, options
    end

    #  @param {string} selector
    #  @param {!{visible?: boolean, hidden?: boolean, timeout?: number}=} options
    #  @return {!Promise<?Puppeteer.ElementHandle>}
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

    # @param {string} xpath
    # @param {!{visible?: boolean, hidden?: boolean, timeout?: number}=} options
    # @return {!Promise<?Puppeteer.ElementHandle>}
    #
    def wait_for_xpath(xpath, visible: nil, hidden: nil, timeout: nil)
      secondary_world.wait_for_xpath(xpath, visible: visible, hidden: hidden, timeout: timeout).then do |handle|
        next if handle.nil?
        result = main_world.execution_context._adopt_element_handle handle
        handle.dispose
        result
      end
    end

    def _detach
      @_detached = true
      main_world._detach
      secondary_world._detach
      # TODO
      parent_frame.instance_variable_get(:@child_frames).delete self if parent_frame
      @parent_frame = nil
    end

    # @param {string} url
    #
    def _navigated_within_document(url)
      @_url = url
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
