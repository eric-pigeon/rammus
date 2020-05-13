# frozen_string_literal: true

module Rammus
  # @!visibility private
  #
  class Launcher
    def self.launch(headless: true)
      tmpdir = Dir.mktmpdir

      chrome_arguments = DEFAULT_ARGS.dup
      chrome_arguments.push(*HEADLESS_ARGS) if headless
      # TODO support pipe as well
      chrome_arguments.push('--remote-debugging-port=0')
      chrome_arguments.push("-user-data-dir=#{tmpdir}")

      stderr_out, stderr_in = IO.pipe
      pid = Process.spawn(executable_path, *chrome_arguments, 2 => stderr_in)
      stderr_in.close

      web_socket_url = wait_for_ws_endpoint(stderr_out)
      ws_client = WebSocketClient.new(web_socket_url)

      client = ChromeClient.new(ws_client)

      close_callback = -> { client.command(Protocol::Browser.close).wait! }

      Browser.new(client: client, close_callback: close_callback, default_viewport: { width: 800, height: 600 }).tap do |browser|
        ObjectSpace.define_finalizer(browser, Launcher.process_killer(pid, tmpdir))
      end
    end

    # TODO
    # @param {!(Launcher.BrowserOptions & {browserWSEndpoint?: string, browserURL?: string, transport?: !Puppeteer.ConnectionTransport})} options
    #
    # @return [Rammus::Browser]
    #
    def self.connect(ws_endpoint:)
      # const {
      #   browserWSEndpoint,
      #   browserURL,
      #   ignoreHTTPSErrors = false,
      #   defaultViewport = {width: 800, height: 600},
      #   transport,
      #   slowMo = 0,
      # } = options;

      # assert(Number(!!browserWSEndpoint) + Number(!!browserURL) + Number(!!transport) === 1, 'Exactly one of browserWSEndpoint, browserURL or transport must be passed to puppeteer.connect');
      ws_client = WebSocketClient.new(ws_endpoint)
      client = ChromeClient.new ws_client
      context_ids = client.command(Protocol::Target.get_browser_contexts).value!
      viewport = { width: 800, height: 600 }
      close_callback = -> { client.command(Protocol::Browser.close).wait! }
      Browser.new(
        client: client,
        context_ids: context_ids,
        default_viewport: viewport,
        close_callback: close_callback
      )

      # let connection = null;
      # if (transport) {
      #   connection = new Connection('', transport, slowMo);
      # } else if (browserWSEndpoint) {
      #   const connectionTransport = await WebSocketTransport.create(browserWSEndpoint);
      #   connection = new Connection(browserWSEndpoint, connectionTransport, slowMo);
      # } else if (browserURL) {
      #   const connectionURL = await getWSEndpoint(browserURL);
      #   const connectionTransport = await WebSocketTransport.create(connectionURL);
      #   connection = new Connection(connectionURL, connectionTransport, slowMo);
      # }

      # const {browserContextIds} = await connection.send('Target.getBrowserContexts');
      # return Browser.create(connection, browserContextIds, ignoreHTTPSErrors, defaultViewport, null, () => connection.send('Browser.close').catch(debugError));
    end

    DEFAULT_ARGS = [
      '--disable-background-networking',
      '--enable-features=NetworkService,NetworkServiceInProcess',
      '--disable-background-timer-throttling',
      '--disable-backgrounding-occluded-windows',
      '--disable-breakpad',
      '--disable-client-side-phishing-detection',
      '--disable-default-apps',
      '--disable-dev-shm-usage',
      '--disable-extensions',
      '--disable-features=site-per-process,TranslateUI,BlinkGenPropertyTrees',
      '--disable-hang-monitor',
      '--disable-ipc-flooding-protection',
      # '--disable-infobars',
      '--disable-popup-blocking',
      '--disable-prompt-on-repost',
      '--disable-renderer-backgrounding',
      '--disable-sync',
      '--force-color-profile=srgb',
      # '--disable-session-crashed-bubble',
      '--metrics-recording-only',
      '--no-first-run',
      # '--safebrowsing-disable-auto-update',
      '--enable-automation',
      '--password-store=basic',
      '--use-mock-keychain',
      'about:blank'
      # '--keep-alive-for-test',
    ].freeze

    HEADLESS_ARGS = [
      '--headless',
      '--hide-scrollbars',
      '--mute-audio'
    ].freeze

    def self.executable_path
      case RbConfig::CONFIG['host_os']
      when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
        raise 'todo'
      when /darwin|mac os/
        macosx_path
      when /linux|solaris|bsd/
        linux_path
      end
      # "/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
      # "/Users/epigeon/Documents/Projects/Node/puppeteer_test/node_modules/puppeteer/.local-chromium/mac-662092/chrome-mac/Chromium.app/Contents/MacOS/Chromium"
    end

    def self.macosx_path
      directories = ['', File.expand_path('~')]
      files = [
        '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
        '/Applications/Chromium.app/Contents/MacOS/Chromium'
      ]
      directories.product(files).map(&:join).detect { |path| File.exist? path }
    end

    def self.linux_path
      directories = %w[/usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /opt/google/chrome]
      files = %w[google-chrome chrome chromium chromium-browser]

      directories
        .product(files)
        .map { |path| path.join('/') }
        .detect { |path| File.exist?(path) }
    end

    # Returns a proc, that when called will attempt to kill the given process.
    # This is because implementing ObjectSpace.define_finalizer is tricky.
    # Hat-Tip to @mperham for describing in detail:
    # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
    #
    def self.process_killer(pid, tmpdir = nil)
      proc do
        if 1.zero? # Capybara::Poltergeist.windows?
          # Process.kill('KILL', pid)
        else
          Process.kill('TERM', pid)
          start = Time.now
          while Process.wait(pid, Process::WNOHANG).nil?
            sleep 0.05
            next unless (Time.now - start) > KILL_TIMEOUT

            Process.kill('KILL', pid)
            Process.wait(pid)
            break
          end
        end
        FileUtils.remove_entry tmpdir if tmpdir
      rescue Errno::ESRCH, Errno::ECHILD
        # Zed's dead, baby
      end
    end

    READ_LENGTH = 1024
    READ_TIMEOUT = 2
    WS_REGEX = %r{^DevTools listening on (ws://.*)$}.freeze

    def self.wait_for_ws_endpoint(io)
      output = ""
      begin
        loop do
          output += io.read_nonblock READ_LENGTH
          if (match = WS_REGEX.match(output))
            return match[1]
          end
        end
      rescue EOFError
        puts output
        raise 'TODO'
      rescue IO::WaitReadable
        raise 'TODO' unless IO.select [io], nil, nil, READ_TIMEOUT

        retry
      end
    end
  end
end
