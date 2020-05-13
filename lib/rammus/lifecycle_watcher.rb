# frozen_string_literal: true

module Rammus
  # @!visibility private
  #
  class LifecycleWatcher
    attr_reader :frame_manager, :frame,
      # Fulfills when the frame and all children frames have all of the expected
      # lifecycle events
      :lifecycle_promise,
      # Fulfills when the CDP Session is disconnected
      :termination_promise,
      # TODO: double defined
      # Fulfills when the request timeouts or terminates
      # :timeout_or_termination_promise,
      # Fulfills when page navigates on the same page, ie anchor links
      :same_document_navigation_promise,
      # Fulfills when page navigates to new url
      :new_document_navigation_promise

    # @param [Rammus::FrameManager] frame_manager
    # @param [Rammus::Frame] frame
    # @param [Array, Symbol] wait_until
    # @param [Integer] timeout
    #
    def initialize(frame_manager:, frame:, wait_until:, timeout: nil)
      @frame_manager = frame_manager
      @frame = frame
      @_initial_loader_id = frame.loader_id
      @timeout = timeout
      @_expected_lifecycle = Array(wait_until).map do |event|
        PROTOCOL_MAPPING.fetch event
      end.to_set
      @_has_same_document_navigation = false
      # @type {?Puppeteer.Request}
      @_navigation_request = nil
      @_event_listeners = [
        Util.add_event_listener(frame_manager.client, :cdp_session_disconnected, ->(_event) { terminate(StandardError.new('Navigation failed because browser has disconnected!')) }),
        Util.add_event_listener(frame_manager.client, Protocol::Inspector.target_crashed, ->(_event) { terminate(Errors::PageCrashed.new("Navigation failed because page crashed")) }),
        Util.add_event_listener(frame_manager, FrameManager.lifecycle_event, method(:check_lifecycle_complete)),
        Util.add_event_listener(frame_manager, :frame_navigated_within_document, method(:navigated_within_document)),
        Util.add_event_listener(frame_manager, :frame_detached, method(:on_frame_detached)),
        Util.add_event_listener(frame_manager.network_manager, :request, method(:on_request))
      ]

      @same_document_navigation_promise = Concurrent::Promises.resolvable_future
      @_same_document_navigation_complete_callback = @same_document_navigation_promise.method(:fulfill)

      @lifecycle_promise = Concurrent::Promises.resolvable_future
      @_lifecycle_callback = @lifecycle_promise.method(:fulfill)

      @new_document_navigation_promise = Concurrent::Promises.resolvable_future
      @_new_document_navigation_complete_callback = @new_document_navigation_promise.method(:fulfill)

      @_timeout_task = nil
      @_timeout_promise =
        if @timeout.nil? || timeout.zero?
          Concurrent::Promises.resolvable_future
        else
          Concurrent::Promises.resolvable_future.tap do |future|
            @_timeout_task = Concurrent::ScheduledTask.execute(@timeout) { future.fulfill nil }
          end.then { Errors::TimeoutError.new "Navigation Timeout Exceeded: #{@timeout}s exceeded" }
        end

      @termination_promise = Concurrent::Promises.resolvable_future
      @_termination_callback = @termination_promise.method(:fulfill)
      # TODO
      # check_lifecycle_complete(nil)
    end

    def timeout_or_termination_promise
      @_timeout_or_termination_promise ||= Concurrent::Promises.any(@_timeout_promise, termination_promise)
    end

    # @return [Rammus::Response]
    #
    def navigation_response
      @_navigation_request ? @_navigation_request.response : nil
    end

    def dispose
      Util.remove_event_listeners @_event_listeners
      @_timeout_task&.cancel
    end

    # @!visibility: private
    #
    # @return [Boolean]
    #
    def self.check_lifecycle(frame, expected_lifecycle)
      expected_lifecycle.subset?(frame.lifecycle_events) && frame.child_frames.all? do |child|
        LifecycleWatcher.check_lifecycle child, expected_lifecycle
      end
    end

    private

      PROTOCOL_MAPPING = {
        load: 'load',
        domcontentloaded: 'DOMContentLoaded',
        networkidle0: 'networkIdle',
        networkidle2: 'networkAlmostIdle'
      }.freeze

      def check_lifecycle_complete(_frame)
        return unless LifecycleWatcher.check_lifecycle(frame, @_expected_lifecycle)

        @_lifecycle_callback.(nil, false)

        # TODO is this ever going to happen?
        return if @frame.loader_id == @_initial_loader_id && !@_has_same_document_navigation

        if @_has_same_document_navigation
          @_same_document_navigation_complete_callback.(nil, false)
        end

        return unless @frame.loader_id != @_initial_loader_id

        @_new_document_navigation_complete_callback.(nil, false)
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
        relieturn if self.frame != frame

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

      # @param [StandardError] error
      #
      def terminate(error)
        @_termination_callback.call error
      end
  end
end
