require 'rammus/js_handle'

module Rammus
  # ElementHandle represents an in-page DOM element. ElementHandles can be
  # created with the page.$ method.
  #
  # ElementHandle prevents DOM element from garbage collection unless the
  # handle is disposed. ElementHandles are auto-disposed when their origin
  # frame gets navigated.
  #
  # ElementHandle instances can be used as arguments in {Page#query_selector_evaluate_function} and
  # {Page#evaluate_function} methods.
  #
  class ElementHandle < JSHandle
    attr_reader :page, :frame_manager

    # @param context [Rammus::ExecutionContext]
    # @param client [Rammus::CDPSession]
    # @param remote_object [Protocol.Runtime.RemoteObject]
    # @param page [Rammus::Page]
    # @param frame_manager [Rammus::FrameManager]
    #
    def initialize(context, client, remote_object, page, frame_manager)
      super context, client, remote_object
      @page = page
      @frame_manager = frame_manager
    end

    # @return [Rammus::ElementHandle]
    #
    def as_element
      self
    end

    # Resolves to the content frame for element handles referencing iframe
    # nodes, or null otherwise
    #
    # @return [Rammus::Frame, nil]
    #
    def content_frame
      node_info = client.command(Protocol::DOM.describe_node(
        object_id: remote_object["objectId"]
      )).value
      return unless node_info.dig("node", "frameId").is_a? String

      frame_manager.frame node_info.dig("node", "frameId")
    end

    # This method scrolls element into view if needed, and then uses
    # {Page#mouse} to hover over the center of the element. If the element is
    # detached from DOM, the method throws an error.
    #
    def hover
      scroll_into_view_if_needed
      point = clickable_point
      page.mouse.move point[:x], point[:y]
    end

    # This method scrolls element into view if needed, and then uses {Page#mouse}
    # to click in the center of the element. If the element is detached from DOM,
    # the method throws an error.
    #
    # @param delay [Integer] Time to wait between mousedown and mouseup in milliseconds. Defaults to 0.
    # @param button [String] Mouse button "left", "right" or "middle" defaults to "left"
    # @param click_count [Integer] number of times to click
    #
    def click(delay: nil, button: Mouse::Button::LEFT, click_count: 1)
      scroll_into_view_if_needed
      point = clickable_point
      page.mouse.click point[:x], point[:y], delay: delay, button: button, click_count: click_count
    end

    # @param file_paths [Array<String>] paths to files to upload
    #
    # @return [nil]
    #
    def upload_file(*file_paths)
      files = file_paths.map { |file_path| File.expand_path file_path }
      object_id = remote_object["objectId"]
      client.command(Protocol::DOM.set_file_input_files(object_id: object_id, files: files)).wait!
      nil
    end

    # This method scrolls element into view if needed, and then uses
    # {Touchscreen#tap} to tap in the center of the element. If the element is
    # detached from DOM, the method throws an error.
    #
    def tap
      scroll_into_view_if_needed
      point = clickable_point
      page.touchscreen.tap point[:x], point[:y]
    end

    # @return [nil]
    #
    def focus
      execution_context.evaluate_function('element => element.focus()', self).wait!
      nil
    end

    # Focuses the element, and then sends a `keydown`, `keypress/input`, and
    # `keyup` event for each character in the text. To press a special key, like
    # `Control` or `ArrowDown`, use {press}.
    #
    # @example Types instantly
    #    element_handle.type 'Hello'
    #
    # @example Types slower, like a user
    #    element_handle.type 'World', delay: 100
    #
    # @param text [String]
    # @param delay [Integer]
    #
    def type(text, delay: nil)
      focus
      page.keyboard.type text, delay: delay
    end

    # Focuses the element, and then uses keyboard.down and keyboard.up.
    #
    # If key is a single character and no modifier keys besides Shift are being
    # held down, a keypress/input event will also be generated. The text option
    # can be specified to force an input event to be generated.
    #
    # NOTE Modifier keys DO effect element_handle#press. Holding down Shift will
    # type the text in upper case.
    #
    # @param key [String] Name of key to press, such as ArrowLeft. See Keyboard for a list of all key names.
    # @param delay [Integer, nil] If specified, generates an input event with this text.
    # @param text [String, nil] Time to wait between keydown and keyup in milliseconds. Defaults to 0.
    #
    def press(key, delay: nil, text: nil)
      focus
      page.keyboard.press key, delay: delay, text: text
    end

    # @return {!Promise<?{x: number, y: number, width: number, height: number}>}
    #
    def bounding_box
     result = get_box_model

     return if result.nil?

     quad = result.dig "model", "border"
     x = [quad[0], quad[2], quad[4], quad[6]].min
     y = [quad[1], quad[3], quad[5], quad[7]].min
     width = [quad[0], quad[2], quad[4], quad[6]].max - x
     height = [quad[1], quad[3], quad[5], quad[7]].max - y

     { x: x, y: y, width: width, height: height }
    end

    # @return {!Promise<?BoxModel>}
    #
    def box_model
      result = get_box_model

      return if result.nil?

      model = result["model"]
      {
        content: from_protocol_quad(model["content"]),
        padding: from_protocol_quad(model["padding"]),
        border: from_protocol_quad(model["border"]),
        margin: from_protocol_quad(model["margin"]),
        width: model["width"],
        height: model["height"]
      }
    end

    # @param {!Object=} options
    # @return {!Promise<string|!Buffer>}
    #
    def screenshot(options = {})
      needs_viewport_reset = false

      bounding_box = self.bounding_box
      raise 'Node is either not visible or not an HTMLElement' unless bounding_box

      viewport = page.viewport

      if viewport && bounding_box[:width] > viewport[:width] || bounding_box[:height] > viewport[:height]
        new_viewport = {
          width: [viewport[:width], bounding_box[:width].ceil].max,
          height: [viewport[:height], bounding_box[:height].ceil].max,
        }
        page.set_viewport viewport.merge(new_viewport)

        needs_viewport_reset = true
      end

      scroll_into_view_if_needed

      bounding_box = self.bounding_box

      raise 'Node is either not visible or not an HTMLElement' if bounding_box.nil?
      raise 'Node has 0 width.' if bounding_box[:width].zero?
      raise 'Node has 0 height.' if bounding_box[:height].zero?

      result = client.command(Protocol::Page.get_layout_metrics).value
      page_x = result.dig "layoutViewport", "pageX"
      page_y = result.dig "layoutViewport", "pageY"

      clip = bounding_box

      clip[:x] += page_x
      clip[:y] += page_y

      image_data = page.screenshot({ clip: clip }.merge(options))

      page.set_viewport viewport if needs_viewport_reset

      image_data
    end

    # @param {string} selector
    # @return {!Promise<?ElementHandle>}
    #
    def query_selector(selector)
      handle = execution_context.evaluate_handle_function(
        '(element, selector) => element.querySelector(selector)',
        self,
        selector
      ).value
      element = handle.as_element

      if element
        element
      else
        handle.dispose
        nil
      end
    end

    # @param {string} selector
    # @return {!Promise<!Array<!ElementHandle>>}
    #
    def query_selector_all(selector)
      array_handle = execution_context.evaluate_handle_function(
        "(element, selector) => element.querySelectorAll(selector)",
        self,
        selector
      ).value
      properties = array_handle.get_properties
      array_handle.dispose

      properties.values.map do |property|
        element_handle = property.as_element

        next if element_handle.nil?

        element_handle
      end.compact
    end

    # @param {string} selector
    # @param {Function|String} pageFunction
    # @param {!Array<*>} args
    # @return {!Promise<(!Object|undefined)>}
    #
    def query_selector_evaluate_function(selector, page_function, *args)
      element_handle = query_selector selector
      if element_handle.nil?
        raise "Error: failed to find element matching selector '#{selector}'"
      end
      result = execution_context.evaluate_function page_function, element_handle, *args
      element_handle.dispose
      result
    end

    # @param {string} selector
    # @param {Function|String} pageFunction
    # @param {!Array<*>} args
    # @return {!Promise<(!Object|undefined)>}
    #
    def query_selector_all_evaluate_function(selector, page_function, *args)
      array_handle = execution_context.evaluate_handle_function(
        "(element, selector) => Array.from(element.querySelectorAll(selector))",
        self,
        selector
      ).value

      result = execution_context.evaluate_function(page_function, array_handle, *args).value
      array_handle.dispose
      result
    end

    # @param {string} expression
    # @return {!Promise<!Array<!ElementHandle>>}
    #
    def xpath(expression)
      function = <<~JAVASCRIPT
      (element, expression) => {
        const document = element.ownerDocument || element;
        const iterator = document.evaluate(expression, element, null, XPathResult.ORDERED_NODE_ITERATOR_TYPE);
        const array = [];
        let item;
        while ((item = iterator.iterateNext()))
          array.push(item);
        return array;
      }
      JAVASCRIPT
      array_handle = execution_context.evaluate_handle_function(function, self, expression).value

      properties = array_handle.get_properties
      array_handle.dispose

      properties.values.map do |property|
        element_handle = property.as_element

        next if element_handle.nil?

        element_handle
      end.compact
    end

    # @return {!Promise<boolean>}
    #
    def is_intersecting_viewport
      function = <<~JAVASCRIPT
      async element => {
        const visibleRatio = await new Promise(resolve => {
          const observer = new IntersectionObserver(entries => {
            resolve(entries[0].intersectionRatio);
            observer.disconnect();
          });
          observer.observe(element);
        });
        return visibleRatio > 0;
      }
      JAVASCRIPT
      execution_context.evaluate_function(function, self).value
    end

    private

      def scroll_into_view_if_needed
        function = <<~JAVASCRIPT
          async(element, pageJavascriptEnabled) => {
            if (!element.isConnected)
              return 'Node is detached from document';
            if (element.nodeType !== Node.ELEMENT_NODE)
              return 'Node is not of type HTMLElement';
            // force-scroll if page's javascript is disabled.
            if (!pageJavascriptEnabled) {
              element.scrollIntoView({block: 'center', inline: 'center', behavior: 'instant'});
              return false;
            }
            const visibleRatio = await new Promise(resolve => {
              const observer = new IntersectionObserver(entries => {
                resolve(entries[0].intersectionRatio);
                observer.disconnect();
              });
              observer.observe(element);
            });
            if (visibleRatio !== 1.0)
              element.scrollIntoView({block: 'center', inline: 'center', behavior: 'instant'});
            return false;
          }
        JAVASCRIPT
        error = execution_context.evaluate_function(function, self, page.javascript_enabled).value
        raise error if error
      end

      # @return {!Promise<!{x: number, y: number}>}
      #
      def clickable_point
        result, layout_metrics = Concurrent::Promises.zip(
          client.command(Protocol::DOM.get_content_quads object_id: remote_object["objectId"]).rescue { |error| Util.debug_error error },
          client.command(Protocol::Page.get_layout_metrics)
        ).value!

        if !result || !result.fetch("quads", []).length
          raise 'Node is either not visible or not an HTMLElement'
        end

        # Filter out quads that have too small area to click into.
        client_width = layout_metrics.dig "layoutViewport", "clientWidth"
        client_height = layout_metrics.dig "layoutViewport", "clientHeight"

        quads = result["quads"]
          .map { |quad| from_protocol_quad quad }
          .map { |quad| intersect_quad_with_viewport quad, client_width, client_height }
          .select { |quad| compute_quad_area(quad) > 1 }

        raise 'Node is either not visible or not an HTMLElement' if quads.length.zero?

        # Return the middle point of the first quad.
        quad = quads[0]
        x, y = 0, 0

        quad.each do |point|
          x += point[:x]
          y += point[:y]
        end

        { x: x / 4, y: y / 4 }
      end

      # @param {!Array<number>} quad
      # @return {!Array<{x: number, y: number}>}
      #
      def from_protocol_quad(quad)
        [
          { x: quad[0], y: quad[1] },
          { x: quad[2], y: quad[3] },
          { x: quad[4], y: quad[5] },
          { x: quad[6], y: quad[7] }
        ]
      end

      # @param {!Array<{x: number, y: number}>} quad
      # @param {number} width
      # @param {number} height
      # @return {!Array<{x: number, y: number}>}
      #
      def intersect_quad_with_viewport(quad, width, height)
        quad.map do |point|
          {
            x: [[point[:x], 0].max, width].min,
            y: [[point[:y], 0].max, height].min
          }
        end
      end

      def compute_quad_area(quad)
        # Compute sum of all directed areas of adjacent triangles
        # https://en.wikipedia.org/wiki/Polygon#Simple_polygons
        area = 0;
        quad.length.times do |i|
          p1 = quad[i]
          p2 = quad[(i + 1) % quad.length]
          area += (p1[:x] * p2[:y] - p2[:x] * p1[:y]) / 2;
        end
        area.abs
      end

      # @return {!Promise<void|Protocol.DOM.getBoxModelReturnValue>}
      #
      def get_box_model
        client.command(Protocol::DOM.get_box_model(
          object_id: remote_object["objectId"]
        )).rescue { |error| Util.debug_error error }.value
      end
  end
end
