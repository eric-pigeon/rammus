module Rammus
  module ProtocolLogger
    extend self

    VT100_CODES = {
      black:   30,
      red:     31,
      green:   32,
      yellow:  33,
      blue:    34,
      magenta: 35,
      cyan:    36,
      white:   37,
      bold:    1,
     }

    def puts_command(text)
      # puts wrap "SEND ► #{text}", :magenta
    end

    def puts_command_response(text)
      # puts wrap "◀ RECV #{text}", :cyan
    end

    def puts_event(text)
      # puts wrap "◀ RECV #{text}", :green
    end

    private

      def wrap(text, color)
        "\e[#{console_code_for(color)}m#{text}\e[0m"
      end

      def console_code_for(color)
        VT100_CODES.fetch(color) { console_code_for(:white) }
      end
  end
end
