module Chromiebara
  class Launcher
    def self.launch(headless: true, args: [])
      tmpdir = Dir.mktmpdir

      chrome_arguments = DEFAULT_ARGS
      if (headless)
        chrome_arguments.push(
          '--headless',
          '--hide-scrollbars',
          '--mute-audio'
        )
      end
      # TODO support pipe as well
      chrome_arguments.push('--remote-debugging-port=0')
      chrome_arguments.push("-user-data-dir=#{tmpdir}")

      stderr_out, stderr_in = IO.pipe
      pid = Process.spawn(executable_path, *chrome_arguments, 2 => stderr_in)
      stderr_in.close

      web_socket_url = wait_for_ws_endpoint(stderr_out)
      ws_client = WebSocketClient.new(web_socket_url)

      client = ChromeClient.new(ws_client)

      Browser.new(client: client).tap do |browser|
        ObjectSpace.define_finalizer(browser, Launcher.process_killer(pid, tmpdir))
      end
    end

    private

      DEFAULT_ARGS = [
        '--disable-background-networking',
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
        '--disable-infobars',
        '--disable-popup-blocking',
        '--disable-prompt-on-repost',
        '--disable-renderer-backgrounding',
        '--disable-sync',
        '--force-color-profile=srgb',
        '--disable-session-crashed-bubble',
        '--metrics-recording-only',
        '--no-first-run',
        '--safebrowsing-disable-auto-update',
        '--enable-automation',
        '--password-store=basic',
        '--use-mock-keychain',
        '--keep-alive-for-test',
      ]

      def self.executable_path
        "/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
      end

      # Returns a proc, that when called will attempt to kill the given process.
      # This is because implementing ObjectSpace.define_finalizer is tricky.
      # Hat-Tip to @mperham for describing in detail:
      # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
      #
      def self.process_killer(pid, tmdir = nil)
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
          FileUtils.remove_entry tmpdir if tmpdir
          rescue Errno::ESRCH, Errno::ECHILD
            # Zed's dead, baby
          end
        end
      end

      READ_LENGTH = 1024
      READ_TIMEOUT = 2
      WS_REGEX = /^DevTools listening on (ws:\/\/.*)$/

      def self.wait_for_ws_endpoint(io)
        output = ""
        begin
          while true
            output += io.read_nonblock READ_LENGTH
            if match = WS_REGEX.match(output)
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
