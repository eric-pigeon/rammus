module Chromiebara
  module Protocol
    module HeadlessExperimental
      extend self

      # Sends a BeginFrame to the target and returns when the frame was completed. Optionally captures a
      # screenshot from the resulting frame. Requires that the target was created with enabled
      # BeginFrameControl. Designed for use with --run-all-compositor-stages-before-draw, see also
      # https://goo.gl/3zHXhB for more background.
      #
      # @param frame_time_ticks [Number] Timestamp of this BeginFrame in Renderer TimeTicks (milliseconds of uptime). If not set, the current time will be used.
      # @param interval [Number] The interval between BeginFrames that is reported to the compositor, in milliseconds. Defaults to a 60 frames/second interval, i.e. about 16.666 milliseconds.
      # @param no_display_updates [Boolean] Whether updates should not be committed and drawn onto the display. False by default. If true, only side effects of the BeginFrame will be run, such as layout and animations, but any visual updates may not be visible on the display or in screenshots.
      # @param screenshot [Screenshotparams] If set, a screenshot of the frame will be captured and returned in the response. Otherwise, no screenshot will be captured. Note that capturing a screenshot can fail, for example, during renderer initialization. In such a case, no screenshot data will be returned.
      #
      def begin_frame(frame_time_ticks: nil, interval: nil, no_display_updates: nil, screenshot: nil)
        {
          method: "HeadlessExperimental.beginFrame",
          params: { frameTimeTicks: frame_time_ticks, interval: interval, noDisplayUpdates: no_display_updates, screenshot: screenshot }.compact
        }
      end

      # Disables headless events for the target.
      #
      def disable
        {
          method: "HeadlessExperimental.disable"
        }
      end

      # Enables headless events for the target.
      #
      def enable
        {
          method: "HeadlessExperimental.enable"
        }
      end

      def needs_begin_frames_changed
        'HeadlessExperimental.needsBeginFramesChanged'
      end
    end
  end
end
