module Chromiebara
  class Page
    extend Forwardable

    attr_reader :target
    delegate [:session] => :target
    delegate [:url] => :main_frame

    def initialize(target)
      @target = target
      @_frameManager = FrameManager.new(session, self)
    end

    def main_frame
      @_frameManager.main_frame
    end
  end
end
