require 'chromiebara/key_definitions'

module Chromiebara
  class Keyboard
    include Promise::Await

    attr_reader :client, :modifiers

    # @param {!Puppeteer.CDPSession} client
    #
    def initialize(client)
      @client = client
      @modifiers = 0
      @_pressed_keys = Set.new
    end

    # @param {string} key
    # @param {{text?: string}=} options
    #
    def down(key, text: nil)
      description = key_description_for_string key

      auto_repeat = @_pressed_keys.include? description[:code]
      @_pressed_keys << description[:code]
      @modifiers |= modifier_bit description[:key]

      text ||= description[:text]

      await client.command(Protocol::Input.dispatch_key_event(
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
      ))
    end

    # @param {string} key
    #
    def up(key)
      description = key_description_for_string key

      @modifiers &= ~(modifier_bit description[:key])
      @_pressed_keys.delete description[:code]

      await client.command(Protocol::Input.dispatch_key_event(
        type: 'keyUp',
        modifiers: modifiers,
        key: description[:key],
        windows_virtual_key_code: description[:key_code],
        code: description[:code],
        location: description[:location]
      ))
    end

    # @param {string} char
    #
    def send_character(char)
      await client.command(Protocol::Input.insert_text text: char)
    end

    # @param {string} text
    # @param {{delay: (number|undefined)}=} options
    #
    def type(text, delay: 0)
      # TODO can we use promise.all here and only wait once instead of waiting
      # for each character
      text.chars.each do |char|
        if KEY_DEFINITIONS[char]
          press char, { delay: delay }
        else
          send_character char
        end
        # if (delay)
        #   await new Promise(f => setTimeout(f, delay));
      end
    end

    # @param {string} key
    # @param {!{delay?: number, text?: string}=} options
    #
    def press(key, delay: 0, text: nil)
      down key, text: text
      # if (delay !== null)
      #   await new Promise(f => setTimeout(f, options.delay));
      up key
    end

    private

      # @param {string} keyString
      #
      # @return {KeyDescription}
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

      # @param {string} key
      # @return {number}
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
