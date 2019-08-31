module Rammus
  # ConsoleMessage objects are dispatched by page via the 'console' event.
  #
  class ConsoleMessage
    attr_reader :type, :text, :args, :location

    # @param type [String]
    # @param text [String]
    # @param args [Array<Rammus::JSHandle>]
    # @param location [Hash]
    #
    def initialize(type, text, args, location = {})
      @type = type
      @text = text
      @args = args
      @location = location
    end
  end
end
