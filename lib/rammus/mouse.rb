module Rammus
  class Mouse
    include Promise::Await

    attr_reader :client, :keyboard

    # @param {Puppeteer.CDPSession} client
    # @param {!Keyboard} keyboard
    #
    def initialize(client, keyboard)
      @client = client
      @keyboard = keyboard
      @_x = 0
      @_y = 0
      # /** @type {'none'|'left'|'right'|'middle'} */
      @_button = 'none'
    end

    # @param {number} x
    # @param {number} y
    # @param {!{steps?: number}=} options
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

    # @param {number} x
    # @param {number} y
    # @param {!{delay?: number, button?: "left"|"right"|"middle", clickCount?: number}=} options
    #
    def click(x, y, options = {})
      # delay = options[:delay]
      move x, y
      down options
      # if (delay !== null)
      #   await new Promise(f => setTimeout(f, delay));
      up options
    end

    # @param {!{button?: "left"|"right"|"middle", clickCount?: number}=} options
    #
    def down(button: 'left', click_count: 1)
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

    # @param {!{button?: "left"|"right"|"middle", clickCount?: number}=} options
    #
    def up(button: 'left', click_count: 1)
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
