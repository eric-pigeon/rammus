# frozen_string_literal: true

module Rammus
  module Protocol
    module Input
      extend self

      # Dispatches a key event to the page.
      #
      # @param type [String] Type of the key event.
      # @param modifiers [Integer] Bit field representing pressed modifier keys. Alt=1, Ctrl=2, Meta/Command=4, Shift=8 (default: 0).
      # @param timestamp [Timesinceepoch] Time at which the event occurred.
      # @param text [String] Text as generated by processing a virtual key code with a keyboard layout. Not needed for for `keyUp` and `rawKeyDown` events (default: "")
      # @param unmodified_text [String] Text that would have been generated by the keyboard if no modifiers were pressed (except for shift). Useful for shortcut (accelerator) key handling (default: "").
      # @param key_identifier [String] Unique key identifier (e.g., 'U+0041') (default: "").
      # @param code [String] Unique DOM defined string value for each physical key (e.g., 'KeyA') (default: "").
      # @param key [String] Unique DOM defined string value describing the meaning of the key in the context of active modifiers, keyboard layout, etc (e.g., 'AltGr') (default: "").
      # @param windows_virtual_key_code [Integer] Windows virtual key code (default: 0).
      # @param native_virtual_key_code [Integer] Native virtual key code (default: 0).
      # @param auto_repeat [Boolean] Whether the event was generated from auto repeat (default: false).
      # @param is_keypad [Boolean] Whether the event was generated from the keypad (default: false).
      # @param is_system_key [Boolean] Whether the event was a system key event (default: false).
      # @param location [Integer] Whether the event was from the left or right side of the keyboard. 1=Left, 2=Right (default: 0).
      #
      def dispatch_key_event(type:, modifiers: nil, timestamp: nil, text: nil, unmodified_text: nil, key_identifier: nil, code: nil, key: nil, windows_virtual_key_code: nil, native_virtual_key_code: nil, auto_repeat: nil, is_keypad: nil, is_system_key: nil, location: nil)
        {
          method: "Input.dispatchKeyEvent",
          params: { type: type, modifiers: modifiers, timestamp: timestamp, text: text, unmodifiedText: unmodified_text, keyIdentifier: key_identifier, code: code, key: key, windowsVirtualKeyCode: windows_virtual_key_code, nativeVirtualKeyCode: native_virtual_key_code, autoRepeat: auto_repeat, isKeypad: is_keypad, isSystemKey: is_system_key, location: location }.compact
        }
      end

      # This method emulates inserting text that doesn't come from a key press,
      # for example an emoji keyboard or an IME.
      #
      # @param text [String] The text to insert.
      #
      def insert_text(text:)
        {
          method: "Input.insertText",
          params: { text: text }.compact
        }
      end

      # Dispatches a mouse event to the page.
      #
      # @param type [String] Type of the mouse event.
      # @param x [Number] X coordinate of the event relative to the main frame's viewport in CSS pixels.
      # @param y [Number] Y coordinate of the event relative to the main frame's viewport in CSS pixels. 0 refers to the top of the viewport and Y increases as it proceeds towards the bottom of the viewport.
      # @param modifiers [Integer] Bit field representing pressed modifier keys. Alt=1, Ctrl=2, Meta/Command=4, Shift=8 (default: 0).
      # @param timestamp [Timesinceepoch] Time at which the event occurred.
      # @param button [String] Mouse button (default: "none").
      # @param buttons [Integer] A number indicating which buttons are pressed on the mouse when a mouse event is triggered. Left=1, Right=2, Middle=4, Back=8, Forward=16, None=0.
      # @param click_count [Integer] Number of times the mouse button was clicked (default: 0).
      # @param delta_x [Number] X delta in CSS pixels for mouse wheel event (default: 0).
      # @param delta_y [Number] Y delta in CSS pixels for mouse wheel event (default: 0).
      # @param pointer_type [String] Pointer type (default: "mouse").
      #
      def dispatch_mouse_event(type:, x:, y:, modifiers: nil, timestamp: nil, button: nil, buttons: nil, click_count: nil, delta_x: nil, delta_y: nil, pointer_type: nil)
        {
          method: "Input.dispatchMouseEvent",
          params: { type: type, x: x, y: y, modifiers: modifiers, timestamp: timestamp, button: button, buttons: buttons, clickCount: click_count, deltaX: delta_x, deltaY: delta_y, pointerType: pointer_type }.compact
        }
      end

      # Dispatches a touch event to the page.
      #
      # @param type [String] Type of the touch event. TouchEnd and TouchCancel must not contain any touch points, while TouchStart and TouchMove must contains at least one.
      # @param touch_points [Array] Active touch points on the touch device. One event per any changed point (compared to previous touch event in a sequence) is generated, emulating pressing/moving/releasing points one by one.
      # @param modifiers [Integer] Bit field representing pressed modifier keys. Alt=1, Ctrl=2, Meta/Command=4, Shift=8 (default: 0).
      # @param timestamp [Timesinceepoch] Time at which the event occurred.
      #
      def dispatch_touch_event(type:, touch_points:, modifiers: nil, timestamp: nil)
        {
          method: "Input.dispatchTouchEvent",
          params: { type: type, touchPoints: touch_points, modifiers: modifiers, timestamp: timestamp }.compact
        }
      end

      # Emulates touch event from the mouse event parameters.
      #
      # @param type [String] Type of the mouse event.
      # @param x [Integer] X coordinate of the mouse pointer in DIP.
      # @param y [Integer] Y coordinate of the mouse pointer in DIP.
      # @param button [String] Mouse button.
      # @param timestamp [Timesinceepoch] Time at which the event occurred (default: current time).
      # @param delta_x [Number] X delta in DIP for mouse wheel event (default: 0).
      # @param delta_y [Number] Y delta in DIP for mouse wheel event (default: 0).
      # @param modifiers [Integer] Bit field representing pressed modifier keys. Alt=1, Ctrl=2, Meta/Command=4, Shift=8 (default: 0).
      # @param click_count [Integer] Number of times the mouse button was clicked (default: 0).
      #
      def emulate_touch_from_mouse_event(type:, x:, y:, button:, timestamp: nil, delta_x: nil, delta_y: nil, modifiers: nil, click_count: nil)
        {
          method: "Input.emulateTouchFromMouseEvent",
          params: { type: type, x: x, y: y, button: button, timestamp: timestamp, deltaX: delta_x, deltaY: delta_y, modifiers: modifiers, clickCount: click_count }.compact
        }
      end

      # Ignores input events (useful while auditing page).
      #
      # @param ignore [Boolean] Ignores input events processing when set to true.
      #
      def set_ignore_input_events(ignore:)
        {
          method: "Input.setIgnoreInputEvents",
          params: { ignore: ignore }.compact
        }
      end

      # Synthesizes a pinch gesture over a time period by issuing appropriate touch events.
      #
      # @param x [Number] X coordinate of the start of the gesture in CSS pixels.
      # @param y [Number] Y coordinate of the start of the gesture in CSS pixels.
      # @param scale_factor [Number] Relative scale factor after zooming (>1.0 zooms in, <1.0 zooms out).
      # @param relative_speed [Integer] Relative pointer speed in pixels per second (default: 800).
      # @param gesture_source_type [Gesturesourcetype] Which type of input events to be generated (default: 'default', which queries the platform for the preferred input type).
      #
      def synthesize_pinch_gesture(x:, y:, scale_factor:, relative_speed: nil, gesture_source_type: nil)
        {
          method: "Input.synthesizePinchGesture",
          params: { x: x, y: y, scaleFactor: scale_factor, relativeSpeed: relative_speed, gestureSourceType: gesture_source_type }.compact
        }
      end

      # Synthesizes a scroll gesture over a time period by issuing appropriate touch events.
      #
      # @param x [Number] X coordinate of the start of the gesture in CSS pixels.
      # @param y [Number] Y coordinate of the start of the gesture in CSS pixels.
      # @param x_distance [Number] The distance to scroll along the X axis (positive to scroll left).
      # @param y_distance [Number] The distance to scroll along the Y axis (positive to scroll up).
      # @param x_overscroll [Number] The number of additional pixels to scroll back along the X axis, in addition to the given distance.
      # @param y_overscroll [Number] The number of additional pixels to scroll back along the Y axis, in addition to the given distance.
      # @param prevent_fling [Boolean] Prevent fling (default: true).
      # @param speed [Integer] Swipe speed in pixels per second (default: 800).
      # @param gesture_source_type [Gesturesourcetype] Which type of input events to be generated (default: 'default', which queries the platform for the preferred input type).
      # @param repeat_count [Integer] The number of times to repeat the gesture (default: 0).
      # @param repeat_delay_ms [Integer] The number of milliseconds delay between each repeat. (default: 250).
      # @param interaction_marker_name [String] The name of the interaction markers to generate, if not empty (default: "").
      #
      def synthesize_scroll_gesture(x:, y:, x_distance: nil, y_distance: nil, x_overscroll: nil, y_overscroll: nil, prevent_fling: nil, speed: nil, gesture_source_type: nil, repeat_count: nil, repeat_delay_ms: nil, interaction_marker_name: nil)
        {
          method: "Input.synthesizeScrollGesture",
          params: { x: x, y: y, xDistance: x_distance, yDistance: y_distance, xOverscroll: x_overscroll, yOverscroll: y_overscroll, preventFling: prevent_fling, speed: speed, gestureSourceType: gesture_source_type, repeatCount: repeat_count, repeatDelayMs: repeat_delay_ms, interactionMarkerName: interaction_marker_name }.compact
        }
      end

      # Synthesizes a tap gesture over a time period by issuing appropriate touch events.
      #
      # @param x [Number] X coordinate of the start of the gesture in CSS pixels.
      # @param y [Number] Y coordinate of the start of the gesture in CSS pixels.
      # @param duration [Integer] Duration between touchdown and touchup events in ms (default: 50).
      # @param tap_count [Integer] Number of times to perform the tap (e.g. 2 for double tap, default: 1).
      # @param gesture_source_type [Gesturesourcetype] Which type of input events to be generated (default: 'default', which queries the platform for the preferred input type).
      #
      def synthesize_tap_gesture(x:, y:, duration: nil, tap_count: nil, gesture_source_type: nil)
        {
          method: "Input.synthesizeTapGesture",
          params: { x: x, y: y, duration: duration, tapCount: tap_count, gestureSourceType: gesture_source_type }.compact
        }
      end
    end
  end
end
