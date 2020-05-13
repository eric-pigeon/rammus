# frozen_string_literal: true

module Rammus
  # BrowserContexts provide a way to operate multiple independent browser
  # sessions. When a browser is launched, it has a single BrowserContext used
  # by default. The method {Browser#new_page} creates a page in the default
  # browser context.
  #
  # If a page opens another page, e.g. with a window.open call, the popup will
  # belong to the parent page's browser context.
  #
  # Rammus allows creation of "incognito" browser contexts with
  # {Browser#create_context} method. "Incognito" browser contexts don't write
  # any browsing data to disk.
  #
  # @example Create a new incognito browser context
  #   context = browser.create_context
  #
  # @example Create a new page inside context.
  #   page = context.new_page
  #   await page.goto 'https://example.com'
  #
  # @example Dispose context once it's no longer needed.
  #    context.close
  #
  class BrowserContext
    include EventEmitter

    attr_reader :id, :browser, :client

    # @!visibility private
    #
    def initialize(browser:, client:, id: nil)
      super()
      @id = id
      @browser = browser
      @client = client
    end

    # Closes the browser context. All the targets that belong to the browser
    # context will be closed.  All pages will be closed without calling their
    # beforeunload hooks.
    #
    # @raise [Errors::UncloseableContext] raised if the context can't be closed
    #
    # @return [nil]
    #
    def close
      raise Errors::UncloseableContext unless id

      browser.delete_context(self)
      nil
    end

    # Creates a new page in the browser context.
    #
    # @return [Rammus::Page]
    #
    def new_page
      browser.create_page_in_context(id)
    end

    # An array of all open pages. Non visible pages, such as "background_page",
    # will not be listed here. You can find them using target.page().
    # An array of all pages inside the browser context.
    #
    # @return [Array<Rammus::Page>]
    #
    def pages
      targets
        .select { |target| target.type == "page" }
        .map(&:page)
        .compact
    end

    # An array of all active targets inside the browser context.
    #
    # @return [Array<Rammus::Target>]
    #
    def targets
      browser.targets.select { |target| target.browser_context == self }
    end

    # Override browser permissions
    #
    # @param origin [String] The origin to grant permissions to, e.g. "https://example.com".
    # @param permissions [Array<String>] An array of permissions to grant. All
    #   permissions that are not listed here will be automatically denied. Permissions
    #   can be one of the following values: ['geolocation' 'midi' 'midi-sysex'
    #   (system-exclusive midi) 'notifications' 'push' 'camera' 'microphone'
    #   'background-sync' 'ambient-light-sensor' 'accelerometer' 'gyroscope'
    #   'magnetometer' 'accessibility-events' 'clipboard-read' 'clipboard-write'
    #   'payment-handler']
    #
    # @return [nil]
    #
    # @example Allowing geolocation
    #   context = browser.default_context
    #   context.override_permissions 'https://html5demos.com', ['geolocation']
    #
    def override_permissions(origin, permissions)
      permissions = permissions.map do |permission|
        protocol_permission = WEB_PERMISSION_TO_PROTOCOL[permission]
        raise "Unknown permission: #{permission}" if protocol_permission.nil?

        protocol_permission
      end
      client.command(Protocol::Browser.grant_permissions(origin: origin, browser_context_id: id || nil, permissions: permissions)).wait!
      nil
    end

    # Clears all permission overrides for the browser context.
    #
    # @example Clearing permission overrides
    #    context = browser.default_context
    #    context.override_permissions 'https://example.com', ['clipboard-read']
    #    context.clear_permission_overrides
    #
    # @return [nil]
    #
    def clear_permission_overrides
      client.command(Protocol::Browser.reset_permissions(browser_context_id: id || nil)).wait!
      nil
    end

    # Search for a target in this context
    #
    # @overload wait_for_target(timeout: 2, predicate:)
    #   @param timeout [Integer] Maximum wait time in milliseconds. Pass 0 to disable the timeout. Defaults to 2 seconds.
    #   @param predicate [#call:Boolean] A callable to be run for every target
    #
    # @overload wait_for_target(timeout: 2, &block)
    #   @param timeout [Integer] Maximum wait time in milliseconds. Pass 0 to disable the timeout. Defaults to 2 seconds.
    #   @yield [Rammus::Target] A block to detect the target
    #
    # @return [Promise<Target>]
    #
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

      def event_queue
        client.send :event_queue
      end

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
      }.freeze
  end
end
