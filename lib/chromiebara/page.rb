module Chromiebara
  class Page
    extend Forwardable

    attr_reader :target
    delegate [:url] => :main_frame

    def initialize(target)
      @target = target
      @_frame_manager = FrameManager.new(client, self)
      # client.send('Target.setAutoAttach', {autoAttach: true, waitForDebuggerOnStart: false, flatten: true}),
      # client.send('Performance.enable', {}),
      # client.send('Log.enable', {}),
    end

    def client
      @client ||= target.session
    end

    def main_frame
      @_frame_manager.main_frame
    end
  end
end
