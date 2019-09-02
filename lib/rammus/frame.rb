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
    include Promise::Await

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
    # @!method add_script_tag(url: nil, path: nil, content: type: '' )
    #    (see Rammus::DOMWorld#add_script_tag)
    #
    # @!method add_style_tag(url: nil, path: nil, content: nil)
    #    (see Rammus::DOMWorld#add_style_tag)
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

    delegate [
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

    # @return [Array<Frame>]
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

    # @!visibility private
    #
    def _detach
      @_detached = true
      main_world._detach
      secondary_world._detach
      # TODO
      parent_frame.instance_variable_get(:@child_frames).delete self if parent_frame
      @parent_frame = nil
    end

    # @!visibility private
    #
    # @param url [String]
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
