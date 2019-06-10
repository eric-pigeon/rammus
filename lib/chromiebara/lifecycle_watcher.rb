module Chromiebara
  # @!visibility private
  class LifecycleWatcher
    include Promise::Await

    attr_reader :frame_manager, :frame, :same_document_navigation_promise, :new_document_navigation_promise

    # @param [Chromiebara::FrameManager] frame_manager
    # @param [Chromiebara::Frame] frame
    # @param [Symbol] wait_until
    # @param [Integer] timeout
    #
    def initialize(frame_manager, frame, wait_until, timeout)
      @frame_manager = frame_manager
      @frame = frame
      @_initial_loader_id = frame.loader_id
      @timeout = timeout || 2
      @_expected_lifecycle = Array(wait_until).map do |event|
        PROTOCOL_MAPPING.fetch event
      end.to_set
      @_has_same_document_navigation = false
      # @type {?Puppeteer.Request}
      @_navigation_request = nil
      @_event_listeners = [
        #helper.addEventListener(frameManager._client, Events.CDPSession.Disconnected, () => this._terminate(new Error('Navigation failed because browser has disconnected!'))),
        Util.add_event_listener(frame_manager, FrameManager.LifecycleEvent, method(:check_lifecycle_complete)),
        Util.add_event_listener(frame_manager, :frame_navigated_within_document, method(:navigated_within_document)),
        # helper.addEventListener(this._frameManager, Events.FrameManager.FrameDetached, this._onFrameDetached.bind(this)),
        Util.add_event_listener(frame_manager.network_manager, :request, method(:on_request))
      ]

      @same_document_navigation_promise, @_same_document_navigation_complete_callback, _ = Promise.create

      @_lifecycle_promise, @_lifecycle_callback, _ = Promise.create

      @new_document_navigation_promise, @_new_document_navigation_complete_callback, _ = Promise.create

      #this._timeoutPromise = this._createTimeoutPromise();
      #this._terminationPromise = new Promise(fulfill => {
      #  this._terminationCallback = fulfill;
      #});
      #this._checkLifecycleComplete();
    end

    # TODO
    def await_complete
      await lifecycle_promise, @timeout
    end

    # * @param {!Puppeteer.Frame} frame
    # */
    #_onFrameDetached(frame) {
    #  if (this._frame === frame) {
    #    this._terminationCallback.call(null, new Error('Navigating frame was detached'));
    #    return;
    #  }
    #  this._checkLifecycleComplete();
    #}

    # @return {?Puppeteer.Response}
    #
    def navigation_response
      @_navigation_request ? @_navigation_request.response : nil
    end

    #   * @param {!Error} error
    #   */
    #  _terminate(error) {
    #    this._terminationCallback.call(null, error);
    #  }

    # @return [Chromiebara::Promise]
    #
    def lifecycle_promise
      @_lifecycle_promise
    end

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

    def dispose
      Util.remove_event_listeners @_event_listeners
    end

    private

      PROTOCOL_MAPPING = {
        load: 'load',
        domcontentloaded: 'DOMContentLoaded',
        networkidle0: 'networkIdle',
        networkidle2: 'networkAlmostIdle'
      }

      def check_lifecycle_complete(_frame)
        return unless LifecycleWatcher.check_lifecycle(frame, @_expected_lifecycle)

        @_lifecycle_callback.(nil)

        # TODO is this ever going to happen?
        return if @frame.loader_id == @_initial_loader_id && !@_has_same_document_navigation

        if @_has_same_document_navigation
          @_same_document_navigation_complete_callback.(nil)
        end

        if @frame.loader_id != @_initial_loader_id
          @_new_document_navigation_complete_callback.(nil)
        end
      end

      # @param {!Puppeteer.Request} request
      #
      def on_request(request)
        return if request.frame != frame || !request.is_navigation_request
        @_navigation_request = request
      end

      # @param {!Puppeteer.Frame} frame
      #
      def navigated_within_document(frame)
        return if frame != frame
        @_has_same_document_navigation = true
        check_lifecycle_complete
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
