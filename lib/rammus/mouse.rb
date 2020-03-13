module Rammus
  # The Mouse class operates in main-frame CSS pixels relative to the top-left
  # corner of the viewport.
  #
  # Every page object has its own Mouse, accessible with page.mouse.
  #
  class Mouse
    module Button
      LEFT = 'left'
      RIGHT = 'right'
      MIDDLE = 'middle'
    end

    # @!visibility private
    #
    attr_reader :client, :keyboard

    # @!visibility private
    #
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

    # Dispatches a mousemove event.
    #
    # @param x [Integer]
    # @param y [Integer]
    # @param steps [Integer] defaults to 1. Sends intermediate mousemove events.
    #
    # @return [nil]
    #
    def move(x, y, steps: 1)
      from_x = @_x
      from_y = @_y
      @_x = x
      @_y = y
      steps.times do |i|
        client.command(Protocol::Input.dispatch_mouse_event(
          type: 'mouseMoved',
          button: @_button,
          x: from_x + (@_x - from_x) * ((i + 1).to_f / steps),
          y: from_y + (@_y - from_y) * ((i + 1).to_f / steps),
          modifiers: keyboard.modifiers
        )).wait!
      end
      nil
    end

    # Shortcut for {Mouse#move}, {Mouse#down} and {Mouse#up}.
    #
    # @param x [Integer]
    # @param y [Integer]
    # @param delay [Integer] Time to wait between mousedown and mouseup in
    #   seconds. Defaults to 0.
    # @param button [String] Mouse button "left", "right" or "middle" defaults
    #   to "left"
    # @param click_count [Integer] number of times to click
    #
    # @return [nil]
    #
    def click(x, y, delay: nil, button: Button::LEFT, click_count: 1)
      move x, y

      down button: button, click_count: click_count
      sleep delay unless delay.nil?
      up button: button, click_count: click_count
      nil
    end

    # Dispatches a mousedown event.
    #
    # @param button [String] Mouse button "left", "right" or "middle" defaults
    #   to "left"
    # @param click_count [Integer] number of times to click
    #
    # @return [nil]
    #
    def down(button: Button::LEFT, click_count: 1)
      @_button = button
      client.command(Protocol::Input.dispatch_mouse_event(
        type: 'mousePressed',
        button: button,
        x: @_x,
        y: @_y,
        modifiers: keyboard.modifiers,
        click_count: click_count
      )).wait!
      nil
    end

    # Dispatches a mouseup event.
    #
    # @param button [String] Mouse button "left", "right" or "middle" defaults
    #   to "left"
    # @param click_count [Integer] number of times to click
    #
    # @return [nil]
    #
    def up(button: Button::LEFT, click_count: 1)
      @_button = 'none'
      client.command(Protocol::Input.dispatch_mouse_event(
        type: 'mouseReleased',
        button: button,
        x: @_x,
        y: @_y,
        modifiers: keyboard.modifiers,
        click_count: click_count
      )).wait!
      nil
    end
  end
end
