module Chromiebara
  class Page
    extend Forwardable

    attr_reader :target
    delegate [:url] => :main_frame

    def initialize(target)
      @target = target
      @_frame_manager = FrameManager.new(client, self)
      client.command Protocol::Target.set_auto_attach auto_attach: true, wait_for_debugger_on_start: false, flatten: true
      client.command Protocol::Performance.enable
      client.command Protocol::Log.enable
      # if (defaultViewport)
        # await page.setViewport(defaultViewport);
    end

    def client
      @client ||= target.session
    end

    def main_frame
      @_frame_manager.main_frame
    end
  end
end
