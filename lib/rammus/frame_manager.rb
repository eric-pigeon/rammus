require 'rammus/execution_context'

module Rammus
  # @!visibility private
  #
  class FrameManager
    include EventEmitter

    UTILITY_WORLD_NAME = '__puppeteer_utility_world__';

    def self.LifecycleEvent
      'FrameManager.LifecycleEvent'
    end

    attr_reader :client, :page, :network_manager, :timeout_settings

    # @param client [Rammus::CDPSession]
    # @param page [Rammus::Page]
    #
    def initialize(client, page, ignore_https_errors, timeout_settings)
      super()
      @client = client
      @page = page

      @network_manager = Network::Manager.new client, self, ignore_https_errors
      @timeout_settings = timeout_settings

      # @type [Hash<String, Frame>]
      @_frames = {}
      # @type [Hash<Integer, ExecutionContext>]
      @_execution_contexts = {}
      # @type [Set<String>]
      @_isolated_worlds = Set.new
      @_main_frame = nil

      client.on Protocol::Page.frame_attached, -> (event) { on_frame_attached event["frameId"], event["parentFrameId"] }
      client.on Protocol::Page.frame_navigated, -> (event) { on_frame_navigated event["frame"] }
      client.on Protocol::Page.navigated_within_document, -> (event) { on_frame_navigated_within_document event["frameId"], event["url"] }
      client.on Protocol::Page.frame_detached, -> (event) { on_frame_detached event["frameId"] }
      client.on Protocol::Page.frame_stopped_loading, -> (event) { on_frame_stopped_loading event["frameId"] }
      client.on Protocol::Runtime.execution_context_created, -> (event) { on_execution_context_created event["context"] }
      client.on Protocol::Runtime.execution_context_destroyed, -> (event) { on_execution_context_destroyed(event["executionContextId"]) }
      client.on Protocol::Runtime.execution_contexts_cleared, method(:on_execution_contexts_cleared)
      client.on Protocol::Page.lifecycle_event, method(:on_lifecycle_event)
    end

    # @return [Concurrent::Promises::Future]
    #
    def start
      _, frame_tree = Concurrent::Promises.zip(
        client.command(Protocol::Page.enable),
        client.command(Protocol::Page.get_frame_tree)
      ).value
      handle_frame_tree frame_tree["frameTree"]
      Concurrent::Promises.zip(
        client.command(Protocol::Page.set_lifecycle_events_enabled enabled: true),
        client.command(Protocol::Runtime.enable).then { ensure_isolated_world UTILITY_WORLD_NAME },
        network_manager.start
      )
    end

    # @return [Rammus::Frame]
    #
    def main_frame
      @_main_frame
    end

    def navigate_frame(frame, url, referer: nil, timeout: nil, wait_until: nil)
      referer ||= network_manager.extra_http_headers[:referer]
      wait_until ||= [:load]
      timeout ||= timeout_settings.navigation_timeout

      Concurrent::Promises.future do
        watcher = LifecycleWatcher.new frame_manager: self, frame: frame, wait_until: wait_until, timeout: timeout

        error, ensure_new_document_navigation = Concurrent::Promises.any(
          navigate(url, referer, frame.id),
          watcher.timeout_or_termination_promise
        ).value!

        if error.nil?
          navigation_promise =
            if ensure_new_document_navigation
              watcher.new_document_navigation_promise
            else
              watcher.same_document_navigation_promise
            end

          error = Concurrent::Promises.any(
            watcher.timeout_or_termination_promise,
            navigation_promise
          ).value!
        end

        watcher.dispose

        raise error unless error.nil?

        watcher.navigation_response
      end
    end

    # @param frame [Rammus::Frame]
    # @param timeout [Integer] Maximum navigation time in seconds, defaults to 2 seconds, pass 0 to disable timeout. The default value can be changed by using the {Page.set_default_navigation_timeout(timeout)} or {Page.set_default_timeout(timeout)} methods.
    # @param wait_until [Array<Symbol>, Symbol] When to consider navigation succeeded, defaults to load. Given an array of event strings, navigation is considered to be successful after all events have been fired. Events can be either:
    #   * :load - consider navigation to be finished when the load event is fired.
    #   * :domcontentloaded - consider navigation to be finished when the DOMContentLoaded event is fired.
    #   * :networkidle0 - consider navigation to be finished when there are no more than 0 network connections for at least 500 ms.
    #   * :networkidle2 - consider navigation to be finished when there are no more than 2 network connections for at least 500 ms.
    #
    # @return [Promise<Rammus::Response, nil>] Promise which resolves to the
    #   main resource response. In case of multiple redirects, the navigation
    #   will resolve with the response of the last redirect. In case of
    #   navigation to a different anchor or navigation due to History API usage,
    #   the navigation will resolve with nil.
    #
    def wait_for_frame_navigation(frame, timeout: nil, wait_until: nil)
      wait_until ||= [:load]
      timeout ||= timeout_settings.navigation_timeout
      watcher = LifecycleWatcher.new frame_manager: self, frame: frame, wait_until: wait_until, timeout: timeout
      Concurrent::Promises.future do
        begin
          error = Concurrent::Promises.any(
            watcher.timeout_or_termination_promise,
            watcher.same_document_navigation_promise,
            watcher.new_document_navigation_promise
          ).value!
          raise error unless error.nil?
          watcher.navigation_response
        ensure
          watcher.dispose
        end
      end
    end

    # @return [Array<Frame>]
    #
    def frames
      @_frames.values
    end

    # @param [String] frame_id
    #
    # @return [Frame, nil]
    #
    def frame(frame_id)
      @_frames[frame_id]
    end

    # @param {number} contextId
    # @return {!ExecutionContext}
    #
    def execution_context_by_id(context_id)
      @_execution_contexts.fetch context_id
    end

    private

      def event_queue
        client.send :event_queue
      end

      def navigate(url, referrer, frame_id)
        Concurrent::Promises.future do
          begin
            response = client.command(Protocol::Page.navigate url: url, referrer: referrer, frame_id: frame_id).value!
            ensure_new_document_navigation = !!response["loaderId"]
            if response["errorText"]
              [StandardError.new("#{response["errorText"]} at #{url}"), ensure_new_document_navigation]
            else
              [nil, ensure_new_document_navigation]
            end
          rescue => error
            [error, false]
          end
        end
      end

      # @param {!Protocol.Page.FrameTree} frameTree
      #
      def handle_frame_tree(frame_tree)
        if frame_tree.dig "frame", "parentId"
          on_frame_attached(frame_tree.dig("frame", "id"), frameTree.dig("frame", "parentId"))
        end
        on_frame_navigated frame_tree["frame"]

        return unless frame_tree["childFrames"]
        frame_tree["childFrames"].each { |child| handle_frame_tree child }
      end

      # @param [String] name
      #
      def ensure_isolated_world(name)
        return if @_isolated_worlds.member? name

        @_isolated_worlds << name
        client.command(Protocol::Page.add_script_to_evaluate_on_new_document(
          source: "//# sourceURL=#{ExecutionContext::EVALUATION_SCRIPT_URL}",
          world_name: name
        )).wait!
        Concurrent::Promises.zip(
         *frames.map do |frame|
           client.command Protocol::Page.create_isolated_world(
             frame_id: frame.id,
             grant_univeral_access: true,
             world_name: name
           )
         end
        ).wait!
      end

      def on_frame_navigated(frame_payload)
        is_main_frame = !frame_payload.has_key?("parentId")
        frame = is_main_frame ? @_main_frame : @_frames.fetch(frame_payload["id"])
        unless is_main_frame || frame
          raise 'We either navigate top level or have old version of the navigated frame'
        end

        # Detach all child frames first.
        if (frame)
          frame.child_frames.each do |child|
            remove_frames_recursively child
          end
        end

        # Update or create main frame.
        if is_main_frame
          if frame
            # Update frame id to retain frame identity on cross-process navigation.
            @_frames.delete frame.id
            # TODO
            frame.instance_variable_set(:@id, frame_payload["id"])
          else
            # Initial main frame navigation.
            frame = Frame.new self, client, nil, frame_payload["id"]
          end
          @_frames[frame_payload['id']] = frame
          @_main_frame = frame;
        end

        # Update frame payload.
        frame.send(:navigated, frame_payload);

        emit :frame_navigated, frame
      end

      # @param {!Protocol.Page.lifecycleEventPayload} event
      #
      def on_lifecycle_event(event)
        frame = @_frames.fetch event["frameId"]
        frame.send(:on_lifecycle_event, event["loaderId"], event["name"]);
        emit(FrameManager.LifecycleEvent, frame);
      end

      # @param [String] frame_id
      # @param [String, nil] parent_frame_id
      #
      def on_frame_attached(frame_id, parent_frame_id)
        return if @_frames.has_key? frame_id
        parent_frame = @_frames.fetch parent_frame_id
        frame = Frame.new(self, client, parent_frame, frame_id)
        @_frames[frame.id] = frame
        emit :frame_attached, frame
      end

      # @param [String] frame_id
      #
      def on_frame_stopped_loading(frame_id)
        return unless frame = @_frames[frame_id]
        frame.send(:on_loading_stopped)
        emit :lifecycle_event, frame
      end

      def on_execution_context_created(context_payload)
        frame_id = context_payload.dig "auxData", "frameId"
        frame = @_frames.fetch frame_id, nil
        world = nil
        if frame
          if context_payload.dig "auxData", "isDefault"
            world = frame.main_world
          elsif context_payload["name"] == UTILITY_WORLD_NAME && !frame.secondary_world.has_context?
            # In case of multiple sessions to the same target, there's a race between
            # connections so we might end up creating multiple isolated worlds.
            # We can use either.
            world = frame.secondary_world
          end
        end
        if context_payload["auxData"] && context_payload.dig("auxData", "type") == 'isolated'
          @_isolated_worlds.add context_payload["name"]
        end
        context = ExecutionContext.new client, context_payload, world
        world.send(:set_context, context) if world
        @_execution_contexts[context_payload["id"]] = context
      end

      #  @param {number} executionContextId
      #
      def on_execution_context_destroyed(execution_context_id)
        context = @_execution_contexts.delete(execution_context_id)
        if context.world
          context.world.send(:set_context, nil)
        end
      end

      def on_execution_contexts_cleared(*)
        @_execution_contexts.values.each do |context|
          context.world.send(:set_context, nil) if context.world
        end

        @_execution_contexts.clear
      end

      # @param {!Frame} frame
      #
      def remove_frames_recursively(frame)
        frame.child_frames.each { |child| remove_frames_recursively child }
        frame._detach
        @_frames.delete frame.id
        emit :frame_detached, frame
      end

      # @param {string} frame_id
      #
      def on_frame_detached(frame_id)
        frame = @_frames[frame_id]

        remove_frames_recursively frame if frame
      end

      # @param {string} frame_id
      # @param {string} url
      #
      def on_frame_navigated_within_document(frame_id, url)
        return unless frame = @_frames[frame_id]
        frame._navigated_within_document url
        emit :frame_navigated_within_document, frame
        emit :frame_navigated, frame
      end
  end
end
