require 'rammus/js_handle'

module Rammus
  # ElementHandle represents an in-page DOM element. ElementHandles can be
  # created with the page.$ method.
  #
  # ElementHandle prevents DOM element from garbage collection unless the
  # handle is disposed. ElementHandles are auto-disposed when their origin
  # frame gets navigated.
  #
  # ElementHandle instances can be used as arguments in page.$eval() and
  # page.evaluate() methods.
  #
  class ElementHandle < JSHandle
    include Promise::Await
    attr_reader :page, :frame_manager

    # @param [Rammus::ExecutionContext] context
    # @param [Rammus::CDPSession] client
    # @param [Protocol.Runtime.RemoteObject] remote_object
    # @param [Rammus::Page] page
    # @param [Rammus::FrameManager] frame_manager
    #
    def initialize(context, client, remote_object, page, frame_manager)
      super context, client, remote_object
      @page = page
      @frame_manager = frame_manager
    end

    # * @override
    # * @return {?ElementHandle}
    #
    def as_element
      self
    end

    # @return {!Promise<?Puppeteer.Frame>}
    #
    def content_frame
      node_info = await client.command Protocol::DOM.describe_node(
        object_id: remote_object["objectId"]
      )
      return unless node_info.dig("node", "frameId").is_a? String

      frame_manager.frame node_info.dig("node", "frameId")
    end

    def hover()
      scroll_into_view_if_needed
      point = clickable_point
      page.mouse.move point[:x], point[:y]
    end

    # * @param {!{delay?: number, button?: "left"|"right"|"middle", clickCount?: number}=} options
    #
    def click(options = {})
      scroll_into_view_if_needed
      point = clickable_point
      page.mouse.click(point[:x], point[:y], options)
    end

    # @param {!Array<string>} file_paths
    #
    def upload_file(*file_paths)
      files = file_paths.map { |file_path| File.expand_path file_path }
      object_id = remote_object["objectId"]
      await client.command Protocol::DOM.set_file_input_files(object_id: object_id, files: files)
    end

    def tap
      scroll_into_view_if_needed
      point = clickable_point
      page.touchscreen.tap point[:x], point[:y]
    end

    def focus
      execution_context.evaluate_function 'element => element.focus()', self
    end

    # @param {string} text
    # @param {{delay: (number|undefined)}=} options
    #
    def type(text, delay: nil)
      focus
      page.keyboard.type text, delay: delay
    end

    # @param {string} key
    # @param {!{delay?: number, text?: string}=} options
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
    # @returns {!Promise<string|!Buffer>}
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

      result = await client.command Protocol::Page.get_layout_metrics
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
      handle = await execution_context.evaluate_handle_function(
        '(element, selector) => element.querySelector(selector)',
        self,
        selector
      )
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
      array_handle = await execution_context.evaluate_handle_function(
        "(element, selector) => element.querySelectorAll(selector)",
        self,
        selector
      )
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
      array_handle = await execution_context.evaluate_handle_function(
        "(element, selector) => Array.from(element.querySelectorAll(selector))",
        self,
        selector
      )

      result = await execution_context.evaluate_function page_function, array_handle, *args
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
      array_handle = await execution_context.evaluate_handle_function function, self, expression

      properties = array_handle.get_properties
      array_handle.dispose

      properties.values.map do |property|
        element_handle = property.as_element

        next if element_handle.nil?

        element_handle
      end.compact
    end

    # @returns {!Promise<boolean>}
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
      await execution_context.evaluate_function function, self
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
        error = await execution_context.evaluate_function function, self, page.javascript_enabled
        raise error if error
      end

      # @return {!Promise<!{x: number, y: number}>}
      #
      def clickable_point
        result, layout_metrics = await Promise.all(
          client.command(Protocol::DOM.get_content_quads object_id: remote_object["objectId"]).catch { |error| Util.debug_error error },
          client.command(Protocol::Page.get_layout_metrics)
        )

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
        await client.command(Protocol::DOM.get_box_model(
          object_id: remote_object["objectId"]
        )).catch { |error| Util.debug_error error }
      end
  end
end
