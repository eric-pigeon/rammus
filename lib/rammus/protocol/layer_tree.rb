module Rammus
  module Protocol
    module LayerTree
      extend self

      # Provides the reasons why the given layer was composited.
      #
      # @param layer_id [Layerid] The id of the layer for which we want to get the reasons it was composited.
      #
      def compositing_reasons(layer_id:)
        {
          method: "LayerTree.compositingReasons",
          params: { layerId: layer_id }.compact
        }
      end

      # Disables compositing tree inspection.
      #
      def disable
        {
          method: "LayerTree.disable"
        }
      end

      # Enables compositing tree inspection.
      #
      def enable
        {
          method: "LayerTree.enable"
        }
      end

      # Returns the snapshot identifier.
      #
      # @param tiles [Array] An array of tiles composing the snapshot.
      #
      def load_snapshot(tiles:)
        {
          method: "LayerTree.loadSnapshot",
          params: { tiles: tiles }.compact
        }
      end

      # Returns the layer snapshot identifier.
      #
      # @param layer_id [Layerid] The id of the layer.
      #
      def make_snapshot(layer_id:)
        {
          method: "LayerTree.makeSnapshot",
          params: { layerId: layer_id }.compact
        }
      end

      # @param snapshot_id [Snapshotid] The id of the layer snapshot.
      # @param min_repeat_count [Integer] The maximum number of times to replay the snapshot (1, if not specified).
      # @param min_duration [Number] The minimum duration (in seconds) to replay the snapshot.
      # @param clip_rect [Dom.rect] The clip rectangle to apply when replaying the snapshot.
      #
      def profile_snapshot(snapshot_id:, min_repeat_count: nil, min_duration: nil, clip_rect: nil)
        {
          method: "LayerTree.profileSnapshot",
          params: { snapshotId: snapshot_id, minRepeatCount: min_repeat_count, minDuration: min_duration, clipRect: clip_rect }.compact
        }
      end

      # Releases layer snapshot captured by the back-end.
      #
      # @param snapshot_id [Snapshotid] The id of the layer snapshot.
      #
      def release_snapshot(snapshot_id:)
        {
          method: "LayerTree.releaseSnapshot",
          params: { snapshotId: snapshot_id }.compact
        }
      end

      # Replays the layer snapshot and returns the resulting bitmap.
      #
      # @param snapshot_id [Snapshotid] The id of the layer snapshot.
      # @param from_step [Integer] The first step to replay from (replay from the very start if not specified).
      # @param to_step [Integer] The last step to replay to (replay till the end if not specified).
      # @param scale [Number] The scale to apply while replaying (defaults to 1).
      #
      def replay_snapshot(snapshot_id:, from_step: nil, to_step: nil, scale: nil)
        {
          method: "LayerTree.replaySnapshot",
          params: { snapshotId: snapshot_id, fromStep: from_step, toStep: to_step, scale: scale }.compact
        }
      end

      # Replays the layer snapshot and returns canvas log.
      #
      # @param snapshot_id [Snapshotid] The id of the layer snapshot.
      #
      def snapshot_command_log(snapshot_id:)
        {
          method: "LayerTree.snapshotCommandLog",
          params: { snapshotId: snapshot_id }.compact
        }
      end

      def layer_painted
        'LayerTree.layerPainted'
      end

      def layer_tree_did_change
        'LayerTree.layerTreeDidChange'
      end
    end
  end
end
