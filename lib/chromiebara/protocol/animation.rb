module Chromiebara
  module Protocol
    module Animation
      extend self

      # Disables animation domain notifications.
      # 
      #
      def disable
        {
          method: "Animation.disable"
        }
      end

      # Enables animation domain notifications.
      # 
      #
      def enable
        {
          method: "Animation.enable"
        }
      end

      # Returns the current time of the an animation.
      # 
      # @param id [String] Id of animation.
      #
      def get_current_time(id:)
        {
          method: "Animation.getCurrentTime",
          params: { id: id }.compact
        }
      end

      # Gets the playback rate of the document timeline.
      # 
      #
      def get_playback_rate
        {
          method: "Animation.getPlaybackRate"
        }
      end

      # Releases a set of animations to no longer be manipulated.
      # 
      # @param animations [Array] List of animation ids to seek.
      #
      def release_animations(animations:)
        {
          method: "Animation.releaseAnimations",
          params: { animations: animations }.compact
        }
      end

      # Gets the remote object of the Animation.
      # 
      # @param animation_id [String] Animation id.
      #
      def resolve_animation(animation_id:)
        {
          method: "Animation.resolveAnimation",
          params: { animationId: animation_id }.compact
        }
      end

      # Seek a set of animations to a particular time within each animation.
      # 
      # @param animations [Array] List of animation ids to seek.
      # @param current_time [Number] Set the current time of each animation.
      #
      def seek_animations(animations:, current_time:)
        {
          method: "Animation.seekAnimations",
          params: { animations: animations, currentTime: current_time }.compact
        }
      end

      # Sets the paused state of a set of animations.
      # 
      # @param animations [Array] Animations to set the pause state of.
      # @param paused [Boolean] Paused state to set to.
      #
      def set_paused(animations:, paused:)
        {
          method: "Animation.setPaused",
          params: { animations: animations, paused: paused }.compact
        }
      end

      # Sets the playback rate of the document timeline.
      # 
      # @param playback_rate [Number] Playback rate for animations on page
      #
      def set_playback_rate(playback_rate:)
        {
          method: "Animation.setPlaybackRate",
          params: { playbackRate: playback_rate }.compact
        }
      end

      # Sets the timing of an animation node.
      # 
      # @param animation_id [String] Animation id.
      # @param duration [Number] Duration of the animation.
      # @param delay [Number] Delay of the animation.
      #
      def set_timing(animation_id:, duration:, delay:)
        {
          method: "Animation.setTiming",
          params: { animationId: animation_id, duration: duration, delay: delay }.compact
        }
      end
    end
  end
end
