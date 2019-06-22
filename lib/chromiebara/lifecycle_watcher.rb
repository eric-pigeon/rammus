module Chromiebara
  # @!visibility private
  class LifecycleWatcher
    include Promise::Await

    attr_reader :frame_manager, :frame,
      # Fulfulls when the frame and all children frames have all of the expected
      # lifecycle events
      :lifecycle_promise,
      # Fulfulls when the CDP Session is disconnected
      :termination_promise,
      :same_document_navigation_promise,
      :new_document_navigation_promise

    # @param [Chromiebara::FrameManager] frame_manager
    # @param [Chromiebara::Frame] frame
    # @param [Symbol] wait_until
    # @param [Integer] timeout # TODO remove
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
        Util.add_event_listener(frame_manager.client, :cdp_session_disconnected, ->(_event) { terminate(StandardError.new('Navigation failed because browser has disconnected!')) }),
        Util.add_event_listener(frame_manager, FrameManager.LifecycleEvent, method(:check_lifecycle_complete)),
        Util.add_event_listener(frame_manager, :frame_navigated_within_document, method(:navigated_within_document)),
        Util.add_event_listener(frame_manager, :frame_detached, method(:on_frame_detached)),
        Util.add_event_listener(frame_manager.network_manager, :request, method(:on_request))
      ]

      @same_document_navigation_promise, @_same_document_navigation_complete_callback, _ = Promise.create

      @lifecycle_promise, @_lifecycle_callback, _ = Promise.create

      @new_document_navigation_promise, @_new_document_navigation_complete_callback, _ = Promise.create

      @termination_promise, @_termination_callback, _ = Promise.create
      check_lifecycle_complete(nil)
    end

    # @return [Chromiebara::Response]
    #
    def navigation_response
      @_navigation_request ? @_navigation_request.response : nil
    end

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
        check_lifecycle_complete nil
      end

      # @param {!Puppeteer.Frame} frame
      #
      def on_frame_detached(frame)
        if self.frame == frame
          @_termination_callback.('Navigating frame was detached')
          return
        end
        check_lifecycle_complete nil
      end

      # @return [Boolean]
      #
      def self.check_lifecycle(frame, expected_lifecycle)
        expected_lifecycle.subset?(frame.lifecycle_events) && frame.child_frames.all? do |child|
          LifecycleWatcher.check_lifecycle child, expected_lifecycle
        end
      end

      # @param [StandardError] error
      #
      def terminate(error)
        @_termination_callback.call error
      end
  end
end
