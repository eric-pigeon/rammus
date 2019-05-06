module Chromiebara
  class FrameManager
    include EventEmitter

    attr_reader :client, :page

    # @param [Chromiebara::CDPSession] client
    # @param [Chromiebara::Page] page
    #
    def initialize(client, page)
      @client = client
      @page = page
      @_frames = {}
      @_main_frame = nil

      # this._client.on('Page.frameAttached', event => this._onFrameAttached(event.frameId, event.parentFrameId));
      client.on 'Page.frameNavigated', -> (event) { on_frame_navigated event["frame"] }
      # this._client.on('Page.frameNavigated', event => this._onFrameNavigated(event.frame));
      # this._client.on('Page.navigatedWithinDocument', event => this._onFrameNavigatedWithinDocument(event.frameId, event.url));
      # this._client.on('Page.frameDetached', event => this._onFrameDetached(event.frameId));
      # this._client.on('Page.frameStoppedLoading', event => this._onFrameStoppedLoading(event.frameId));
      # this._client.on('Runtime.executionContextCreated', event => this._onExecutionContextCreated(event.context));
      # this._client.on('Runtime.executionContextDestroyed', event => this._onExecutionContextDestroyed(event.executionContextId));
      # this._client.on('Runtime.executionContextsCleared', event => this._onExecutionContextsCleared());
      client.on 'Page.lifecycleEvent', method(:on_lifecycle_event)

      client.command Protocol::Page.enable
      client.command(Protocol::Page.get_frame_tree).tap do |frame_tree|
        handle_frame_tree frame_tree["frameTree"]
      end
      client.command Protocol::Page.set_lifecycle_events_enabled enabled: true
      client.command Protocol::Runtime.enable
    end

    # @return [Chromiebara::Frame]
    #
    def main_frame
      @_main_frame
    end

    # /**
    #  * @return {!NetworkManager}
    #  */
    # networkManager() {
    #   return this._networkManager;
    # }

    # @param [String] url
    # TODO
    #
    def navigate_frame(frame, url, referrer: nil, timeout: nil, wait_until: nil)
      # referrer || network_manager.extrea_http_headers['referer']
      wait_until ||= [:load]
      # timeout ||= timeout_settings.navigation_timeou

      # TODO just hacking this in here
      client.command Protocol::Page.navigate url: url, referrer: referrer, frame_id: frame.id

      #   const watcher = new LifecycleWatcher(this, frame, waitUntil, timeout);
      #   let ensureNewDocumentNavigation = false;
      #   let error = await Promise.race([
      #     navigate(this._client, url, referer, frame._id),
      #     watcher.timeoutOrTerminationPromise(),
      #   ]);
      #   if (!error) {
      #     error = await Promise.race([
      #       watcher.timeoutOrTerminationPromise(),
      #       ensureNewDocumentNavigation ? watcher.newDocumentNavigationPromise() : watcher.sameDocumentNavigationPromise(),
      #     ]);
      #   }
      #   watcher.dispose();
      #   if (error)
      #     throw error;
      #   return watcher.navigationResponse();

      #   /**
      #    * @param {!Puppeteer.CDPSession} client
      #    * @param {string} url
      #    * @param {string} referrer
      #    * @param {string} frameId
      #    * @return {!Promise<?Error>}
      #    */
      #   async function navigate(client, url, referrer, frameId) {
      #     try {
      #       const response = await client.send('Page.navigate', {url, referrer, frameId});
      #       ensureNewDocumentNavigation = !!response.loaderId;
      #       return response.errorText ? new Error(`${response.errorText} at ${url}`) : null;
      #     } catch (error) {
      #       return error;
      #     }
      #   }
    end

    # /**
    #  * @param {!Puppeteer.Frame} frame
    #  * @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
    #  * @return {!Promise<?Puppeteer.Response>}
    #  */
    # async waitForFrameNavigation(frame, options = {}) {
    #   assertNoLegacyNavigationOptions(options);
    #   const {
    #     waitUntil = ['load'],
    #     timeout = this._timeoutSettings.navigationTimeout(),
    #   } = options;
    #   const watcher = new LifecycleWatcher(this, frame, waitUntil, timeout);
    #   const error = await Promise.race([
    #     watcher.timeoutOrTerminationPromise(),
    #     watcher.sameDocumentNavigationPromise(),
    #     watcher.newDocumentNavigationPromise()
    #   ]);
    #   watcher.dispose();
    #   if (error)
    #     throw error;
    #   return watcher.navigationResponse();
    # }

    # /**
    #  * @param {string} frameId
    #  */
    # _onFrameStoppedLoading(frameId) {
    #   const frame = this._frames.get(frameId);
    #   if (!frame)
    #     return;
    #   frame._onLoadingStopped();
    #   this.emit(Events.FrameManager.LifecycleEvent, frame);
    # }

    # /**
    #  * @param {!Protocol.Page.FrameTree} frameTree
    #  */
    # _handleFrameTree(frameTree) {
    #   if (frameTree.frame.parentId)
    #     this._onFrameAttached(frameTree.frame.id, frameTree.frame.parentId);
    #   this._onFrameNavigated(frameTree.frame);
    #   if (!frameTree.childFrames)
    #     return;

    #   for (const child of frameTree.childFrames)
    #     this._handleFrameTree(child);
    # }

    # /**
    #  * @return {!Puppeteer.Page}
    #  */
    # page() {
    #   return this._page;
    # }

    # /**
    #  * @return {!Frame}
    #  */
    # mainFrame() {
    #   return this._mainFrame;
    # }

    # /**
    #  * @return {!Array<!Frame>}
    #  */
    # frames() {
    #   return Array.from(this._frames.values());
    # }

    # /**
    #  * @param {!string} frameId
    #  * @return {?Frame}
    #  */
    # frame(frameId) {
    #   return this._frames.get(frameId) || null;
    # }

    # /**
    #  * @param {string} frameId
    #  * @param {?string} parentFrameId
    #  */
    # _onFrameAttached(frameId, parentFrameId) {
    #   if (this._frames.has(frameId))
    #     return;
    #   assert(parentFrameId);
    #   const parentFrame = this._frames.get(parentFrameId);
    #   const frame = new Frame(this, this._client, parentFrame, frameId);
    #   this._frames.set(frame._id, frame);
    #   this.emit(Events.FrameManager.FrameAttached, frame);
    # }

    # /**
    #  * @param {!Protocol.Page.Frame} framePayload
    #  */
    # _onFrameNavigated(framePayload) {
    #   const isMainFrame = !framePayload.parentId;
    #   let frame = isMainFrame ? this._mainFrame : this._frames.get(framePayload.id);
    #   assert(isMainFrame || frame, 'We either navigate top level or have old version of the navigated frame');

    #   // Detach all child frames first.
    #   if (frame) {
    #     for (const child of frame.childFrames())
    #       this._removeFramesRecursively(child);
    #   }

    #   // Update or create main frame.
    #   if (isMainFrame) {
    #     if (frame) {
    #       // Update frame id to retain frame identity on cross-process navigation.
    #       this._frames.delete(frame._id);
    #       frame._id = framePayload.id;
    #     } else {
    #       // Initial main frame navigation.
    #       frame = new Frame(this, this._client, null, framePayload.id);
    #     }
    #     this._frames.set(framePayload.id, frame);
    #     this._mainFrame = frame;
    #   }

    #   // Update frame payload.
    #   frame._navigated(framePayload);

    #   this.emit(Events.FrameManager.FrameNavigated, frame);
    # }

    # /**
    #  * @param {string} name
    #  */
    # async _ensureIsolatedWorld(name) {
    #   if (this._isolatedWorlds.has(name))
    #     return;
    #   this._isolatedWorlds.add(name);
    #   await this._client.send('Page.addScriptToEvaluateOnNewDocument', {
    #     source: `//# sourceURL=${EVALUATION_SCRIPT_URL}`,
    #     worldName: name,
    #   }),
    #   await Promise.all(this.frames().map(frame => this._client.send('Page.createIsolatedWorld', {
    #     frameId: frame._id,
    #     grantUniveralAccess: true,
    #     worldName: name,
    #   })));
    # }

    # /**
    #  * @param {string} frameId
    #  * @param {string} url
    #  */
    # _onFrameNavigatedWithinDocument(frameId, url) {
    #   const frame = this._frames.get(frameId);
    #   if (!frame)
    #     return;
    #   frame._navigatedWithinDocument(url);
    #   this.emit(Events.FrameManager.FrameNavigatedWithinDocument, frame);
    #   this.emit(Events.FrameManager.FrameNavigated, frame);
    # }

    # /**
    #  * @param {string} frameId
    #  */
    # _onFrameDetached(frameId) {
    #   const frame = this._frames.get(frameId);
    #   if (frame)
    #     this._removeFramesRecursively(frame);
    # }

    # _onExecutionContextCreated(contextPayload) {
    #   const frameId = contextPayload.auxData ? contextPayload.auxData.frameId : null;
    #   const frame = this._frames.get(frameId) || null;
    #   let world = null;
    #   if (frame) {
    #     if (contextPayload.auxData && !!contextPayload.auxData['isDefault']) {
    #       world = frame._mainWorld;
    #     } else if (contextPayload.name === UTILITY_WORLD_NAME && !frame._secondaryWorld._hasContext()) {
    #       // In case of multiple sessions to the same target, there's a race between
    #       // connections so we might end up creating multiple isolated worlds.
    #       // We can use either.
    #       world = frame._secondaryWorld;
    #     }
    #   }
    #   if (contextPayload.auxData && contextPayload.auxData['type'] === 'isolated')
    #     this._isolatedWorlds.add(contextPayload.name);
    #   /** @type {!ExecutionContext} */
    #   const context = new ExecutionContext(this._client, contextPayload, world);
    #   if (world)
    #     world._setContext(context);
    #   this._contextIdToContext.set(contextPayload.id, context);
    # }

    # /**
    #  * @param {number} executionContextId
    #  */
    # _onExecutionContextDestroyed(executionContextId) {
    #   const context = this._contextIdToContext.get(executionContextId);
    #   if (!context)
    #     return;
    #   this._contextIdToContext.delete(executionContextId);
    #   if (context._world)
    #     context._world._setContext(null);
    # }

    # _onExecutionContextsCleared() {
    #   for (const context of this._contextIdToContext.values()) {
    #     if (context._world)
    #       context._world._setContext(null);
    #   }
    #   this._contextIdToContext.clear();
    # }

    # /**
    #  * @param {number} contextId
    #  * @return {!ExecutionContext}
    #  */
    # executionContextById(contextId) {
    #   const context = this._contextIdToContext.get(contextId);
    #   assert(context, 'INTERNAL ERROR: missing context with id = ' + contextId);
    #   return context;
    # }

    # /**
    #  * @param {!Frame} frame
    #  */
    # _removeFramesRecursively(frame) {
    #   for (const child of frame.childFrames())
    #     this._removeFramesRecursively(child);
    #   frame._detach();
    #   this._frames.delete(frame._id);
    #   this.emit(Events.FrameManager.FrameDetached, frame);
    # }

    private

      # /**
      #  * @param {!Protocol.Page.FrameTree} frameTree
      #  */
      def handle_frame_tree(frame_tree)
        if frame_tree.dig "frame", "parentId"
          # on_frame_attached(frame_tree.dig("frame", "id"), frameTree.frame.parentId);
        end
        on_frame_navigated frame_tree["frame"]
        # this._onFrameNavigated(frameTree.frame);
        # if (!frameTree.childFrames)
        #   return;

        # for (const child of frameTree.childFrames)
        #   this._handleFrameTree(child);
      end

      def on_frame_navigated(frame_payload)
        is_main_frame = !frame_payload.has_key?("parentId")
        frame = is_main_frame ? @_main_frame : @_frams.fetch(frame_payload["id"])
        # assert(isMainFrame || frame, 'We either navigate top level or have old version of the navigated frame');

        # Detach all child frames first.
        #   if (frame) {
        #     for (const child of frame.childFrames())
        #       this._removeFramesRecursively(child);
        #   }

        # Update or create main frame.
        if is_main_frame
          if frame
            # Update frame id to retain frame identity on cross-process navigation.
            #    this._frames.delete(frame._id);
            #    frame._id = framePayload.id;
          else
            # Initial main frame navigation.
            frame = Frame.new self, client, nil, frame_payload["id"]
          end
          @_frames[frame_payload['id']] = frame
          @_main_frame = frame;
        end

        # Update frame payload.
        frame.send(:navigated, frame_payload);

        #   this.emit(Events.FrameManager.FrameNavigated, frame);
      end

      #  * @param {!Protocol.Page.lifecycleEventPayload} event
      #
      def on_lifecycle_event(event)
        frame = @_frames.fetch event["frameId"]
        frame.send(:on_lifecycle_event, event["loaderId"], event["name"]);
        # TODO
      #   this.emit(Events.FrameManager.LifecycleEvent, frame);
      end

  end
end
