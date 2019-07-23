module Rammus
  class ConsoleMessage
    attr_reader :type, :text, :args, :location

    # @param {string} type
    # @param {string} text
    # @param {!Array<!Puppeteer.JSHandle>} args
    # @param {ConsoleMessage.Location} location
    #
    def initialize(type, text, args, location = {})
      @type = type
      @text = text
      @args = args
      @location = location
    end
  end
end
