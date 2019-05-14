module Chromiebara
  # @!visibility private
  class LifecycleWatcher
    include Promise::Await

    attr_reader :frame_manager, :frame

    # @param [Chromiebara::FrameManager] frame_manager
    # @param [Chromiebara::Frame] frame
    # @param [Symbol] wait_until
    # @param [Integer] timeout
    #
    def initialize(frame_manager, frame, wait_until, timeout)
      @frame_manager = frame_manager
      @frame = frame
      @_initial_loader_id = frame.loader_id
      @timeout = timeout
      @_expected_lifecycle = Array(wait_until).map do |event|
        PROTOCOL_MAPPING.fetch event
      end.to_set
      @_has_same_document_navigation = false
      # @_complete_promise = Promise.new
      frame_manager.on(FrameManager.LifecycleEvent, method(:check_lifecycle_complete))

      lifecycle_callback = nil
      @_lifecycle_promise = Promise.new do |fulfill|
        lifecycle_callback = fulfill
      end
      @_lifecycle_callback = lifecycle_callback
    end

    # TODO
    def await_complete
      await lifecycle_promise
      # @_complete_promise.await
    end

#   * @param {!Puppeteer.Frame} frame
#   * @param {string|!Array<string>} waitUntil
#   * @param {number} timeout
#   */
#  constructor(frameManager, frame, waitUntil, timeout) {
#    if (Array.isArray(waitUntil))
#      waitUntil = waitUntil.slice();
#    else if (typeof waitUntil === 'string')
#      waitUntil = [waitUntil];
#
#    /** @type {?Puppeteer.Request} */
#    this._navigationRequest = null;
#    this._eventListeners = [
#      helper.addEventListener(frameManager._client, Events.CDPSession.Disconnected, () => this._terminate(new Error('Navigation failed because browser has disconnected!'))),
#      helper.addEventListener(this._frameManager, Events.FrameManager.LifecycleEvent, this._checkLifecycleComplete.bind(this)),
#      helper.addEventListener(this._frameManager, Events.FrameManager.FrameNavigatedWithinDocument, this._navigatedWithinDocument.bind(this)),
#      helper.addEventListener(this._frameManager, Events.FrameManager.FrameDetached, this._onFrameDetached.bind(this)),
#      helper.addEventListener(this._frameManager.networkManager(), Events.NetworkManager.Request, this._onRequest.bind(this)),
#    ];
#
#    this._sameDocumentNavigationPromise = new Promise(fulfill => {
#      this._sameDocumentNavigationCompleteCallback = fulfill;
#    });
#
#    this._lifecyclePromise = new Promise(fulfill => {
#      this._lifecycleCallback = fulfill;
#    });
#
#    this._newDocumentNavigationPromise = new Promise(fulfill => {
#      this._newDocumentNavigationCompleteCallback = fulfill;
#    });
#
#    this._timeoutPromise = this._createTimeoutPromise();
#    this._terminationPromise = new Promise(fulfill => {
#      this._terminationCallback = fulfill;
#    });
#    this._checkLifecycleComplete();
#  }
#
#  /**
#   * @param {!Puppeteer.Request} request
#   */
#  _onRequest(request) {
#    if (request.frame() !== this._frame || !request.isNavigationRequest())
#      return;
#    this._navigationRequest = request;
#  }
#
#  /**
#   * @param {!Puppeteer.Frame} frame
#   */
#  _onFrameDetached(frame) {
#    if (this._frame === frame) {
#      this._terminationCallback.call(null, new Error('Navigating frame was detached'));
#      return;
#    }
#    this._checkLifecycleComplete();
#  }
#
#  /**
#   * @return {?Puppeteer.Response}
#   */
#  navigationResponse() {
#    return this._navigationRequest ? this._navigationRequest.response() : null;
#  }
#
#  /**
#   * @param {!Error} error
#   */
#  _terminate(error) {
#    this._terminationCallback.call(null, error);
#  }
#
#  /**
#   * @return {!Promise<?Error>}
#   */
#  sameDocumentNavigationPromise() {
#    return this._sameDocumentNavigationPromise;
#  }
#
#  /**
#   * @return {!Promise<?Error>}
#   */
#  newDocumentNavigationPromise() {
#    return this._newDocumentNavigationPromise;
#  }

    # @return [Chromiebara::Promise]
    #
    def lifecycle_promise
      @_lifecycle_promise
    end

#
#  /**
#   * @return {!Promise<?Error>}
#   */
#  timeoutOrTerminationPromise() {
#    return Promise.race([this._timeoutPromise, this._terminationPromise]);
#  }
#
#  /**
#   * @return {!Promise<?Error>}
#   */
#  _createTimeoutPromise() {
#    if (!this._timeout)
#      return new Promise(() => {});
#    const errorMessage = 'Navigation Timeout Exceeded: ' + this._timeout + 'ms exceeded';
#    return new Promise(fulfill => this._maximumTimer = setTimeout(fulfill, this._timeout))
#        .then(() => new TimeoutError(errorMessage));
#  }
#
#  /**
#   * @param {!Puppeteer.Frame} frame
#   */
#  _navigatedWithinDocument(frame) {
#    if (frame !== this._frame)
#      return;
#    this._hasSameDocumentNavigation = true;
#    this._checkLifecycleComplete();
#  }
#

#  dispose() {
#    helper.removeEventListeners(this._eventListeners);
#    clearTimeout(this._maximumTimer);
#  }
    private

      PROTOCOL_MAPPING = {
        load: 'load',
        domcontentloaded: 'DOMContentLoaded',
        networkidle0: 'networkIdle',
        networkidle2: 'networkAlmostIdle'
      }

      def check_lifecycle_complete(_frame)
        return unless LifecycleWatcher.check_lifecycle(frame, @_expected_lifecycle)

        @_lifecycle_callback.(true)
        # this._lifecycleCallback();

        # TODO is this ever going to happen?
        return if @frame.loader_id == @_initial_loader_id && !@_has_same_document_navigation
        # if (this._hasSameDocumentNavigation)
        #   this._sameDocumentNavigationCompleteCallback();
        if @frame.loader_id != @_initial_loader_id
        end
        #   this._newDocumentNavigationCompleteCallback();

        # @_complete_promise.resolve true
      end

      # @return [Boolean]
      #
      def self.check_lifecycle(frame, expected_lifecycle, indentation = '')
        expected_lifecycle.subset?(frame.lifecycle_events) && frame.child_frames.all? do |child|
          LifecycleWatcher.check_lifecycle child, expected_lifecycle, indentation + "  "
        end
      end
  end
end
