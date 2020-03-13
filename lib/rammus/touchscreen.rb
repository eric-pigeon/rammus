module Rammus
  class Touchscreen
    # @!visibility private
    #
    # @param client [Rammus::CDPSession]
    # @param keyboard [Rammus::Keyboard]
    #
    def initialize(client, keyboard)
      @_client = client
      @_keyboard = keyboard
    end

    # Dispatches a touchstart and touchend event.
    #
    # @param x [Numeric]
    # @param y [Numeric]
    #
    # @return [nil]
    #
    def tap(x, y)
      # Touches appear to be lost during the first frame after navigation.
      # This waits a frame before sending the tap.
      # @see https://crbug.com/613219
      @_client.command(Protocol::Runtime.evaluate(
        expression: 'new Promise(x => requestAnimationFrame(() => requestAnimationFrame(x)))',
        await_promise: true
      )).wait!

      touch_points = [{ x: x.round, y: y.round }]
      @_client.command(Protocol::Input.dispatch_touch_event(
        type: 'touchStart',
        touch_points: touch_points,
        modifiers: @_keyboard.modifiers
      )).wait!
      @_client.command(Protocol::Input.dispatch_touch_event(
        type: 'touchEnd',
        touch_points: [],
        modifiers: @_keyboard.modifiers
      )).wait!
    end
  end
end
