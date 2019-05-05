module Chromiebara
  class FrameManager
    attr_reader :client, :page

    # @param [Chromiebara::CDPSession] client
    # @param [Chromiebara::Page] page
    #
    def initialize(client, page)
      @client = client
      @page = page
      @_frames = {}
      @_main_frame = nil
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
  end
end
