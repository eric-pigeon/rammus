module Chromiebara
  class Page
    extend Forwardable

    delegate [:url] => :main_frame

    def initialize(client, target)
      @client = client
      @target = target
      @_frameManager = FrameManager.new(client, self)
    end

    def main_frame
      @_frameManager.main_frame
    end
  end
end
