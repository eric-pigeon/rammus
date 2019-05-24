require 'chromiebara/js_handle'

module Chromiebara
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

    # @param [Chromiebara::ExecutionContext] context
    # @param [Chromiebara::CDPSession] client
    # @param [Protocol.Runtime.RemoteObject] remote_object
    # @param [Chromiebara::Page] page
    # @param [Chromiebara::FrameManager] frame_manager
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

    #/**
    # * @return {!Promise<?Puppeteer.Frame>}
    # */
    #async contentFrame() {
    #  const nodeInfo = await this._client.send('DOM.describeNode', {
    #    objectId: this._remoteObject.objectId
    #  });
    #  if (typeof nodeInfo.node.frameId !== 'string')
    #    return null;
    #  return this._frameManager.frame(nodeInfo.node.frameId);
    #}

    #async _scrollIntoViewIfNeeded() {
    #  const error = await this.executionContext().evaluate(async(element, pageJavascriptEnabled) => {
    #    if (!element.isConnected)
    #      return 'Node is detached from document';
    #    if (element.nodeType !== Node.ELEMENT_NODE)
    #      return 'Node is not of type HTMLElement';
    #    // force-scroll if page's javascript is disabled.
    #    if (!pageJavascriptEnabled) {
    #      element.scrollIntoView({block: 'center', inline: 'center', behavior: 'instant'});
    #      return false;
    #    }
    #    const visibleRatio = await new Promise(resolve => {
    #      const observer = new IntersectionObserver(entries => {
    #        resolve(entries[0].intersectionRatio);
    #        observer.disconnect();
    #      });
    #      observer.observe(element);
    #    });
    #    if (visibleRatio !== 1.0)
    #      element.scrollIntoView({block: 'center', inline: 'center', behavior: 'instant'});
    #    return false;
    #  }, this, this._page._javascriptEnabled);
    #  if (error)
    #    throw new Error(error);
    #}

    #/**
    # * @return {!Promise<!{x: number, y: number}>}
    # */
    #async _clickablePoint() {
    #  const [result, layoutMetrics] = await Promise.all([
    #    this._client.send('DOM.getContentQuads', {
    #      objectId: this._remoteObject.objectId
    #    }).catch(debugError),
    #    this._client.send('Page.getLayoutMetrics'),
    #  ]);
    #  if (!result || !result.quads.length)
    #    throw new Error('Node is either not visible or not an HTMLElement');
    #  // Filter out quads that have too small area to click into.
    #  const {clientWidth, clientHeight} = layoutMetrics.layoutViewport;
    #  const quads = result.quads.map(quad => this._fromProtocolQuad(quad)).map(quad => this._intersectQuadWithViewport(quad, clientWidth, clientHeight)).filter(quad => computeQuadArea(quad) > 1);
    #  if (!quads.length)
    #    throw new Error('Node is either not visible or not an HTMLElement');
    #  // Return the middle point of the first quad.
    #  const quad = quads[0];
    #  let x = 0;
    #  let y = 0;
    #  for (const point of quad) {
    #    x += point.x;
    #    y += point.y;
    #  }
    #  return {
    #    x: x / 4,
    #    y: y / 4
    #  };
    #}

    #/**
    # * @return {!Promise<void|Protocol.DOM.getBoxModelReturnValue>}
    # */
    #_getBoxModel() {
    #  return this._client.send('DOM.getBoxModel', {
    #    objectId: this._remoteObject.objectId
    #  }).catch(error => debugError(error));
    #}

    #/**
    # * @param {!Array<number>} quad
    # * @return {!Array<{x: number, y: number}>}
    # */
    #_fromProtocolQuad(quad) {
    #  return [
    #    {x: quad[0], y: quad[1]},
    #    {x: quad[2], y: quad[3]},
    #    {x: quad[4], y: quad[5]},
    #    {x: quad[6], y: quad[7]}
    #  ];
    #}

    #/**
    # * @param {!Array<{x: number, y: number}>} quad
    # * @param {number} width
    # * @param {number} height
    # * @return {!Array<{x: number, y: number}>}
    # */
    #_intersectQuadWithViewport(quad, width, height) {
    #  return quad.map(point => ({
    #    x: Math.min(Math.max(point.x, 0), width),
    #    y: Math.min(Math.max(point.y, 0), height),
    #  }));
    #}

    #async hover() {
    #  await this._scrollIntoViewIfNeeded();
    #  const {x, y} = await this._clickablePoint();
    #  await this._page.mouse.move(x, y);
    #}

    #/**
    # * @param {!{delay?: number, button?: "left"|"right"|"middle", clickCount?: number}=} options
    # */
    #async click(options) {
    #  await this._scrollIntoViewIfNeeded();
    #  const {x, y} = await this._clickablePoint();
    #  await this._page.mouse.click(x, y, options);
    #}

    #/**
    # * @param {!Array<string>} filePaths
    # */
    #async uploadFile(...filePaths) {
    #  const files = filePaths.map(filePath => path.resolve(filePath));
    #  const objectId = this._remoteObject.objectId;
    #  await this._client.send('DOM.setFileInputFiles', { objectId, files });
    #}

    #async tap() {
    #  await this._scrollIntoViewIfNeeded();
    #  const {x, y} = await this._clickablePoint();
    #  await this._page.touchscreen.tap(x, y);
    #}

    #async focus() {
    #  await this.executionContext().evaluate(element => element.focus(), this);
    #}

    #/**
    # * @param {string} text
    # * @param {{delay: (number|undefined)}=} options
    # */
    #async type(text, options) {
    #  await this.focus();
    #  await this._page.keyboard.type(text, options);
    #}

    #/**
    # * @param {string} key
    # * @param {!{delay?: number, text?: string}=} options
    # */
    #async press(key, options) {
    #  await this.focus();
    #  await this._page.keyboard.press(key, options);
    #}

    #/**
    # * @return {!Promise<?{x: number, y: number, width: number, height: number}>}
    # */
    #async boundingBox() {
    #  const result = await this._getBoxModel();

    #  if (!result)
    #    return null;

    #  const quad = result.model.border;
    #  const x = Math.min(quad[0], quad[2], quad[4], quad[6]);
    #  const y = Math.min(quad[1], quad[3], quad[5], quad[7]);
    #  const width = Math.max(quad[0], quad[2], quad[4], quad[6]) - x;
    #  const height = Math.max(quad[1], quad[3], quad[5], quad[7]) - y;

    #  return {x, y, width, height};
    #}

    #/**
    # * @return {!Promise<?BoxModel>}
    # */
    #async boxModel() {
    #  const result = await this._getBoxModel();

    #  if (!result)
    #    return null;

    #  const {content, padding, border, margin, width, height} = result.model;
    #  return {
    #    content: this._fromProtocolQuad(content),
    #    padding: this._fromProtocolQuad(padding),
    #    border: this._fromProtocolQuad(border),
    #    margin: this._fromProtocolQuad(margin),
    #    width,
    #    height
    #  };
    #}

    #/**
    # *
    # * @param {!Object=} options
    # * @returns {!Promise<string|!Buffer>}
    # */
    #async screenshot(options = {}) {
    #  let needsViewportReset = false;

    #  let boundingBox = await this.boundingBox();
    #  assert(boundingBox, 'Node is either not visible or not an HTMLElement');

    #  const viewport = this._page.viewport();

    #  if (viewport && (boundingBox.width > viewport.width || boundingBox.height > viewport.height)) {
    #    const newViewport = {
    #      width: Math.max(viewport.width, Math.ceil(boundingBox.width)),
    #      height: Math.max(viewport.height, Math.ceil(boundingBox.height)),
    #    };
    #    await this._page.setViewport(Object.assign({}, viewport, newViewport));

    #    needsViewportReset = true;
    #  }

    #  await this._scrollIntoViewIfNeeded();

    #  boundingBox = await this.boundingBox();
    #  assert(boundingBox, 'Node is either not visible or not an HTMLElement');
    #  assert(boundingBox.width !== 0, 'Node has 0 width.');
    #  assert(boundingBox.height !== 0, 'Node has 0 height.');

    #  const { layoutViewport: { pageX, pageY } } = await this._client.send('Page.getLayoutMetrics');

    #  const clip = Object.assign({}, boundingBox);
    #  clip.x += pageX;
    #  clip.y += pageY;

    #  const imageData = await this._page.screenshot(Object.assign({}, {
    #    clip
    #  }, options));

    #  if (needsViewportReset)
    #    await this._page.setViewport(viewport);

    #  return imageData;
    #}

    # @param {string} selector
    # @return {!Promise<?ElementHandle>}
    #
    def query_selector(selector)
      handle = execution_context.evaluate_handle_function(
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

    #/**
    # * @param {string} selector
    # * @return {!Promise<!Array<!ElementHandle>>}
    # */
    #async $$(selector) {
    #  const arrayHandle = await this.executionContext().evaluateHandle(
    #      (element, selector) => element.querySelectorAll(selector),
    #      this, selector
    #  );
    #  const properties = await arrayHandle.getProperties();
    #  await arrayHandle.dispose();
    #  const result = [];
    #  for (const property of properties.values()) {
    #    const elementHandle = property.asElement();
    #    if (elementHandle)
    #      result.push(elementHandle);
    #  }
    #  return result;
    #}

    #/**
    # * @param {string} selector
    # * @param {Function|String} pageFunction
    # * @param {!Array<*>} args
    # * @return {!Promise<(!Object|undefined)>}
    # */
    #async $eval(selector, pageFunction, ...args) {
    #  const elementHandle = await this.$(selector);
    #  if (!elementHandle)
    #    throw new Error(`Error: failed to find element matching selector "${selector}"`);
    #  const result = await this.executionContext().evaluate(pageFunction, elementHandle, ...args);
    #  await elementHandle.dispose();
    #  return result;
    #}

    #/**
    # * @param {string} selector
    # * @param {Function|String} pageFunction
    # * @param {!Array<*>} args
    # * @return {!Promise<(!Object|undefined)>}
    # */
    #async $$eval(selector, pageFunction, ...args) {
    #  const arrayHandle = await this.executionContext().evaluateHandle(
    #      (element, selector) => Array.from(element.querySelectorAll(selector)),
    #      this, selector
    #  );

    #  const result = await this.executionContext().evaluate(pageFunction, arrayHandle, ...args);
    #  await arrayHandle.dispose();
    #  return result;
    #}

    #/**
    # * @param {string} expression
    # * @return {!Promise<!Array<!ElementHandle>>}
    # */
    #async $x(expression) {
    #  const arrayHandle = await this.executionContext().evaluateHandle(
    #      (element, expression) => {
    #        const document = element.ownerDocument || element;
    #        const iterator = document.evaluate(expression, element, null, XPathResult.ORDERED_NODE_ITERATOR_TYPE);
    #        const array = [];
    #        let item;
    #        while ((item = iterator.iterateNext()))
    #          array.push(item);
    #        return array;
    #      },
    #      this, expression
    #  );
    #  const properties = await arrayHandle.getProperties();
    #  await arrayHandle.dispose();
    #  const result = [];
    #  for (const property of properties.values()) {
    #    const elementHandle = property.asElement();
    #    if (elementHandle)
    #      result.push(elementHandle);
    #  }
    #  return result;
    #}

    #/**
    # * @returns {!Promise<boolean>}
    # */
    #isIntersectingViewport() {
    #  return this.executionContext().evaluate(async element => {
    #    const visibleRatio = await new Promise(resolve => {
    #      const observer = new IntersectionObserver(entries => {
    #        resolve(entries[0].intersectionRatio);
    #        observer.disconnect();
    #      });
    #      observer.observe(element);
    #    });
    #    return visibleRatio > 0;
    #  }, this);
    #}
  end
end
