module Chromiebara
  class Launcher
    def self.launch
      tmpdir = Dir.mktmpdir
      Browser.new(tmpdir)

      stderr_out, stderr_in = IO.pipe
    end

    private

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
        # TODO: Support OOOPIF. @see https://github.com/GoogleChrome/puppeteer/issues/2548
        # BlinkGenPropertyTrees disabled due to crbug.com/937609
        '--disable-features=site-per-process,TranslateUI,BlinkGenPropertyTrees',
        '--disable-hang-monitor',
        '--disable-ipc-flooding-protection',
        '--disable-popup-blocking',
        '--disable-prompt-on-repost',
        '--disable-renderer-backgrounding',
        '--disable-sync',
        '--force-color-profile=srgb',
        '--metrics-recording-only',
        '--no-first-run',
        '--enable-automation',
        '--password-store=basic',
        '--use-mock-keychain',
      ]

      def self.command
        [
          "/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome",
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
          '--disable-popup-blocking',
          '--disable-prompt-on-repost',
          '--disable-renderer-backgrounding',
          '--disable-sync',
          '--force-color-profile=srgb',
          '--metrics-recording-only',
          '--no-first-run',
          '--safebrowsing-disable-auto-update',
          '--enable-automation',
          '--password-store=basic',
          '--use-mock-keychain',
          '--headless',
          '--hide-scrollbars',
          '--mute-audio',
          "--headless",
          "--remote-debugging-port=0"
        ]
      end


      # stderr_out, stderr_in = IO.pipe
      # pid = Process.spawn(*command.map(&:to_s), 2 => stderr_in)
      # ObjectSpace.define_finalizer(self, Launcher.process_killer(pid))
      # stderr_in.close

      # @websocket_url = wait_for_ws_endpoint(stderr_out)



    # @return [Chromiebara::Browser]
    # def self.launch(*args)
    #   new(*args).tap(&:launch)

    #   Browser.new.tap do |browser|
    #     browser.pid
    #     browser.tmpdir
    #     ObjectSpace.define_finalizer(browser, Launcher.process_killer())
    #   end
    # end

    # Returns a proc, that when called will attempt to kill the given process.
    # This is because implementing ObjectSpace.define_finalizer is tricky.
    # Hat-Tip to @mperham for describing in detail:
    # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
    def self.process_killer(pid, tmdir)
      proc do
        begin
          # if Capybara::Poltergeist.windows?
          #   Process.kill('KILL', pid)
          # else
            Process.kill('TERM', pid)
            start = Time.now
            while Process.wait(pid, Process::WNOHANG).nil?
              sleep 0.05
              next unless (Time.now - start) > KILL_TIMEOUT
              Process.kill('KILL', pid)
              Process.wait(pid)
              break
            end
          # end
        FileUtils.remove_entry tmpdir
        rescue Errno::ESRCH, Errno::ECHILD
          # Zed's dead, baby
        end
      end
    end

    attr_reader :options

    def initialize(headless: true, **options)
      @options = options.merge(
        'user-data-dir' => Dir.mktmpdir
      )
    end

    def launch
      stderr_out, stderr_in = IO.pipe
      pid = Process.spawn(*command.map(&:to_s), 2 => stderr_in)
      ObjectSpace.define_finalizer(self, Launcher.process_killer(pid))
      stderr_in.close

      @websocket_url = wait_for_ws_endpoint(stderr_out)
    end

    def websocket_url
      @websocket_url
    end

    private

      READ_LENGTH = 1024
      READ_TIMEOUT = 2
      WS_REGEX = /^DevTools listening on (ws:\/\/.*)$/

      def wait_for_ws_endpoint(io)
        output = ""
        begin
          while true
            output += io.read_nonblock READ_LENGTH
            if match = WS_REGEX.match(output)
              return match[1]
            end
          end
        rescue EOFError
          raise 'TODO'
        rescue IO::WaitReadable
          raise 'TODO' unless IO.select [io], nil, nil, READ_TIMEOUT
          retry
        end
      end

      def command
        [
          "/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome",
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
          '--disable-popup-blocking',
          '--disable-prompt-on-repost',
          '--disable-renderer-backgrounding',
          '--disable-sync',
          '--force-color-profile=srgb',
          '--metrics-recording-only',
          '--no-first-run',
          '--safebrowsing-disable-auto-update',
          '--enable-automation',
          '--password-store=basic',
          '--use-mock-keychain',
          '--headless',
          '--hide-scrollbars',
          '--mute-audio',
          "--headless",
          "--remote-debugging-port=0"
        ]
      end
  end
end
