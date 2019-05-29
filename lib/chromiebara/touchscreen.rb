module Chromiebara
  class Touchscreen
    include Promise::Await

    # @param [Chromiebara::CDPSession] client
    # @param [Chromiebara::Keyboard] keyboard
    #
    def initialize(client, keyboard)
      @_client = client
      @_keyboard = keyboard
    end

    # @param [Numeric] x
    # @param [Numeric] y
    #
    def tap(x, y)
      # Touches appear to be lost during the first frame after navigation.
      # This waits a frame before sending the tap.
      # @see https://crbug.com/613219
      await @_client.command Protocol::Runtime.evaluate(
        expression: 'new Promise(x => requestAnimationFrame(() => requestAnimationFrame(x)))',
        await_promise: true
      )

      touch_points = [{ x: x.round, y: y.round }]
      await @_client.command Protocol::Input.dispatch_touch_event(
        type: 'touchStart',
        touch_points: touch_points,
        modifiers: @_keyboard.modifiers
      )
      await @_client.command Protocol::Input.dispatch_touch_event(
        type: 'touchEnd',
        touch_points: [],
        modifiers: @_keyboard.modifiers
      )
    end
  end
end
