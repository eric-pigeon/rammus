module Chromiebara
  class Browser
    extend Forwardable
    delegate [:visit] => :current_page

    def initialize(client, logger = nil)
      @client = client
      @current_page_handle = nil
      @pages = {}
      @context_id = nil
      @js_errors = true
      @ignore_https_errors = false
      @logger = logger
      # @console = Console.new(logger)
      @proxy_auth = nil

      # initialize_handlers

      # command('Target.setDiscoverTargets', discover: true)
      # yield self if block_given?
      # reset
    end


    private

      def command(name, params = {})
        result = client.send_cmd(name, params).result
        log result

        result || raise(Capybara::Apparition::ObsoleteNode.new(nil, nil))
      rescue DeadClient
        restart
        raise
      end
  end
end
