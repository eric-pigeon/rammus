module Rammus
  class Mouse
    module Button
      LEFT = 'left'
      RIGHT = 'right'
      MIDDLE = 'middle'
    end

    include Promise::Await

    attr_reader :client, :keyboard

    # @param client [Rammus::CDPSession]
    # @param keyboard [Rammus::Keyboard]
    #
    def initialize(client, keyboard)
      @client = client
      @keyboard = keyboard
      @_x = 0
      @_y = 0
      # @type {'none'|'left'|'right'|'middle'}
      @_button = 'none'
    end

    # @param x [Integer]
    # @param y [Integer]
    # @param steps [Integer]
    #
    def move(x, y, steps: 1)
      from_x = @_x
      from_y = @_y
      @_x = x
      @_y = y
      steps.times do |i|
        await client.command Protocol::Input.dispatch_mouse_event(
          type: 'mouseMoved',
          button: @_button,
          x: from_x + (@_x - from_x) * ((i + 1).to_f / steps),
          y: from_y + (@_y - from_y) * ((i + 1).to_f / steps),
          modifiers: keyboard.modifiers
        )
      end
    end

    # @param x [Integer]
    # @param y [Integer]
    # @param delay [Integer] Time to wait between mousedown and mouseup in milliseconds. Defaults to 0.
    # @param button [String] Mouse button "left", "right" or "middle" defaults to "left"
    # @param click_count [Integer] number of times to click
    #
    def click(x, y, delay: nil, button: Button::LEFT, click_count: 1)
      move x, y

      down button: button, click_count: click_count
      sleep delay unless delay.nil?
      up button: button, click_count: click_count
    end

    # @param button [String] Mouse button "left", "right" or "middle" defaults to "left"
    # @param click_count [Integer] number of times to click
    #
    def down(button: Button::LEFT, click_count: 1)
      @_button = button
      await client.command Protocol::Input.dispatch_mouse_event(
        type: 'mousePressed',
        button: button,
        x: @_x,
        y: @_y,
        modifiers: keyboard.modifiers,
        click_count: click_count
      )
    end

    # @param button [String] Mouse button "left", "right" or "middle" defaults to "left"
    # @param click_count [Integer] number of times to click
    #
    def up(button: Button::LEFT, click_count: 1)
      @_button = 'none'
      await client.command Protocol::Input.dispatch_mouse_event(
        type: 'mouseReleased',
        button: button,
        x: @_x,
        y: @_y,
        modifiers: keyboard.modifiers,
        click_count: click_count
      )
    end
  end
end
