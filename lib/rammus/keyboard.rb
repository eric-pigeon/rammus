require 'rammus/key_definitions'

module Rammus
  # Keyboard provides an api for managing a virtual keyboard. The high level
  # api is {Keyboard#type}, which takes raw characters and generates proper
  # keydown, keypress/input, and keyup events on your page.
  #
  # For finer control, you can use {Keyboard#down}, {Keyboard#up}, and
  # {Keyboard#send_character| to manually fire events as if they were generated
  # from a real keyboard.
  #
  # @example holding down Shift in order to select and delete some text:
  #   page.keyboard.type 'Hello World!'
  #   page.keyboard.press 'ArrowLeft'
  #
  #   page.keyboard.down 'Shift'
  #
  #   ' World'.length.times { page.keyboard.press 'ArrowLeft' }
  #   page.keyboard.up 'Shift'
  #
  #   page.keyboard.press 'Backspace'
  #   # Result text will end up saying 'Hello!'
  #
  # @example pressing A
  #    page.keyboard.down 'Shift'
  #    page.keyboard.press 'KeyA'
  #    page.keyboard.up 'Shift'
  #
  class Keyboard
    # @!visibility private
    #
    attr_reader :client, :modifiers

    # @!visibility private
    #
    # @param client [Rammus::CDPSession]
    #
    def initialize(client)
      @client = client
      @modifiers = 0
      @_pressed_keys = Set.new
    end

    # Dispatches a keydown event.
    #
    # If key is a single character and no modifier keys besides Shift are being
    # held down, a keypress/input event will also generated. The text option
    # can be specified to force an input event to be generated.
    #
    # If key is a modifier key, Shift, Meta, Control, or Alt, subsequent key
    # presses will be sent with that modifier active. To release the modifier
    # key, use {Keyboard#up}.
    #
    # After the key is pressed once, subsequent calls to {Keyboard#down} will
    # have repeat set to true. To release the key, use {Keyboard#up}.
    #
    # @note Modifier keys DO influence {Keyboard#down}. Holding down Shift will
    #   type the text in upper case.
    #
    # @param key [String] Name of key to press, such as ArrowLeft. See
    #   USKeyboardLayout for a list of all key names.
    # @param text [String] If specified, generates an input event with this text.
    #
    # @return [nil]
    #
    def down(key, text: nil)
      description = key_description_for_string key

      auto_repeat = @_pressed_keys.include? description[:code]
      @_pressed_keys << description[:code]
      @modifiers |= modifier_bit description[:key]

      text ||= description[:text]

      client.command(Protocol::Input.dispatch_key_event(
        type: text != "" ? 'keyDown' : 'rawKeyDown',
        modifiers: modifiers,
        windows_virtual_key_code: description[:key_code],
        code: description[:code],
        key: description[:key],
        text: text,
        unmodified_text: text,
        auto_repeat: auto_repeat,
        location: description[:location],
        is_keypad: description[:location] == 3
      )).value!
      nil
    end

    # Dispatches a keyup event.
    #
    # @param key [String] Name of key to release, such as ArrowLeft. See
    #   USKeyboardLayout for a list of all key names.
    #
    # @return [nil]
    #
    def up(key)
      description = key_description_for_string key

      @modifiers &= ~(modifier_bit description[:key])
      @_pressed_keys.delete description[:code]

      client.command(Protocol::Input.dispatch_key_event(
        type: 'keyUp',
        modifiers: modifiers,
        key: description[:key],
        windows_virtual_key_code: description[:key_code],
        code: description[:code],
        location: description[:location]
      )).wait!
    end

    # Dispatches a keypress and input event. This does not send a keydown or keyup event.
    #
    # @note Modifier keys DO NOT effect {Keyboard#send_character}. Holding down
    #   Shift will not type the text in upper case.
    #
    # @example
    #    page.keyboard.send_character '嗨'
    #
    # @param char [String] Character to send into the page.
    #
    # @return [nil]
    #
    def send_character(char)
      client.command(Protocol::Input.insert_text text: char).wait!
      nil
    end

    # Sends a keydown, keypress/input, and keyup event for each character in
    # the text.
    #
    # @note Modifier keys DO NOT effect {Keyboard#type}. Holding down Shift
    #   will not type the text in upper case.
    #
    # @example typing instantly
    #    page.keyboard.type 'Hello'
    # @example typing slower like a user
    #    page.keyboard.type 'World', delay: 100
    #
    # @param text [String] A text to type into a focused element.
    # @param delay [Integer] Time to wait between key presses in seconds.
    #   Defaults to 0.
    #
    # @return [nil]
    #
    def type(text, delay: 0)
      text.chars.each do |char|
        if KEY_DEFINITIONS[char]
          press char, { delay: delay }
        else
          send_character char
        end
        sleep delay unless delay.nil? || delay.zero?
      end
    end

    # Shortcut for {Keyboard#down} and {Keyboard#up}.
    #
    # If key is a single character and no modifier keys besides Shift are being
    # held down, a keypress/input event will also generated. The text option
    # can be specified to force an input event to be generated.
    #
    # @note Modifier keys DO effect {Keyboard#press}. Holding down Shift will
    #   type the text in upper case.
    #
    # @param key [String] Name of key to press, such as ArrowLeft. See
    #   USKeyboardLayout for a list of all key names.
    # @param text [String] If specified, generates an input event with this text.
    # @param delay [Integer] Time to wait between keydown and keyup in seconds.
    #   Defaults to 0.
    #
    # @return [nil]
    #
    def press(key, delay: 0, text: nil)
      down key, text: text
      sleep delay unless delay.nil? || delay.zero?
      up key
    end

    private

      # @param key_string [String]
      #
      def key_description_for_string(key_string)
        shift = modifiers & 8
        description = {
          key: '',
          key_code: 0,
          code: '',
          text: '',
          location: 0
        }

        definition = KEY_DEFINITIONS[key_string]
        raise "Unknown key: '#{key_string}'" if definition.nil?

        if definition[:key]
          description[:key] = definition[:key]
        end
        if shift && definition[:shift_key]
          description[:key] = definition[:shift_key]
        end

        if definition[:key_code]
          description[:key_code] = definition[:key_code]
        end
        if shift && definition[:shift_key_code]
          description[:key_code] = definition[:shift_key_code]
        end

        if definition[:code]
          description[:code] = definition[:code]
        end

        if definition[:location]
          description[:location] = definition[:location]
        end

        if description[:key].length == 1
          description[:text] = description[:key]
        end

        if definition[:text]
          description[:text] = definition[:text]
        end
        if shift && definition[:shift_text]
          description[:text] = definition[:shift_text]
        end

        # if any modifiers besides shift are pressed, no text should be sent
        unless (modifiers & ~8).zero?
          description[:text] = ''
        end

        description
      end

      # @param key [String]
      #
      # @return [Integer]
      #
      def modifier_bit(key)
        case key
        when 'Alt'     then 1
        when 'Control' then 2
        when 'Meta'    then 4
        when 'Shift'   then 8
        else 0
        end
      end
  end
end
