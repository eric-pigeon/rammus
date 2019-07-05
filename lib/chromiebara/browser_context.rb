module Chromiebara
  class BrowserContext
    include Promise::Await
    include EventEmitter
    class UncloseableContext < StandardError; end

    attr_reader :id, :browser, :client

    def initialize(browser:, client:, id: nil)
      super()
      @id = id
      @browser = browser
      @client = client
    end

    # Closes the browser context. All the targets that belong to the browser context will be closed.
    # All pages will be closed without calling their beforeunload hooks.
    #
    def close
      raise UncloseableContext unless id
      browser.delete_context(self)
    end

    # Creates a new page in the browser context.
    #
    # @return [Chromiebara::Page]
    #
    def new_page
      browser.create_page_in_context(self.id)
    end

    # An array of all open pages. Non visible pages, such as "background_page",
    # will not be listed here. You can find them using target.page().
    # An array of all pages inside the browser context.
    #
    # @return [Array<Chromiebara::Page>]
    #
    def pages
      targets
        .select { |target| target.type == "page" }
        .map(&:page)
        .compact
    end

    # An array of all active targets inside the browser context.
    #
    # @return [Array<Chromiebara::Target>]
    #
    def targets
      browser.targets.select { |target| target.browser_context == self }
    end

    def override_permissions(origin, permissions)
      permissions = permissions.map do |permission|
        protocol_permission = WEB_PERMISSION_TO_PROTOCOL[permission]
        raise "Unknown permission: #{permission}" if protocol_permission.nil?
        protocol_permission
      end
      await client.command Protocol::Browser.grant_permissions origin: origin, browser_context_id: id || nil, permissions: permissions
    end

    def clear_permission_overrides
      await client.command Protocol::Browser.reset_permissions browser_context_id: id || nil
    end

    def wait_for_target(timeout: 2, predicate: nil, &block)
      predicate ||= block
      browser.wait_for_target(timeout: timeout) { |target| target.browser_context == self && predicate.(target) }
    end

    # Returns whether BrowserContext is incognito. The default browser context
    # is the only non-incognito browser context.
    #
    # @return[Boolean]
    #
    def incognito?
      !id.nil?
    end

    private

      WEB_PERMISSION_TO_PROTOCOL = {
        'geolocation' => 'geolocation',
        'midi' => 'midi',
        'notifications' => 'notifications',
        'push' => 'push',
        'camera' => 'videoCapture',
        'microphone' => 'audioCapture',
        'background-sync' => 'backgroundSync',
        'ambient-light-sensor' => 'sensors',
        'accelerometer' => 'sensors',
        'gyroscope' => 'sensors',
        'magnetometer' => 'sensors',
        'accessibility-events' => 'accessibilityEvents',
        'clipboard-read' => 'clipboardRead',
        'clipboard-write' => 'clipboardWrite',
        'payment-handler' => 'paymentHandler',
        # chrome-specific permissions we have.
        'midi-sysex' => 'midiSysex'
      }
  end
end
