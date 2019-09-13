module Rammus
  # You can use {Tracing#start} and {Tracing#stop} to create a trace file which
  # can be opened in Chrome DevTools or
  # {https://chromedevtools.github.io/timeline-viewer timeline viewer}.
  #
  # @example
  #   await page.tracing.start path: 'trace.json'
  #   await page.goto 'https://www.google.com'
  #   await page.tracing.stop
  #
  class Tracing
    include Promise::Await

    # @!visibility private
    #
    attr_reader :client

    # @!visibility private
    #
    # @param client [Rammus::CDPSession]
    #
    def initialize(client)
      @client = client
      @_recording = false
      @_path = ''
    end

    # Start tracing
    #
    # @note Only one trace can be active at a time per browser.
    #
    # @param path [String] A path to write the trace file to.
    # @param screenshots [boolean] captures screenshots in the trace.
    # @param categories [Array<String>] specify custom categories to use instead
    #   of default.
    #
    # @overload
    #   @yield Block to run with tracing
    #   @return [String]
    #
    # @overload
    #   @return [nil]
    #
    def start(path: nil, screenshots: false, categories: DEFAULT_CATEGORIES)
      raise 'Cannot start recording trace while already recording trace.' if @_recording

      categories << 'disabled-by-default-devtools.screenshot' if screenshots

      @_path = path
      @_recording = true
      await client.command Protocol::Tracing.start(
        transfer_mode: 'ReturnAsStream',
        categories: categories.join(',')
      )
      if block_given?
        yield
        stop
      end
    end

    # End trace and get results
    #
    # @return [String] trace data
    #
    def stop
      content_promise, fulfill, _ = Promise.create
      client.once Protocol::Tracing.tracing_complete, -> (event) do
        fulfill.call read_stream event["stream"], @_path
      end
      await client.command Protocol::Tracing.end
      @_recording = false
      await content_promise
    end

    private

      DEFAULT_CATEGORIES = [
        '-*',
        'devtools.timeline',
        'v8.execute',
        'disabled-by-default-devtools.timeline',
        'disabled-by-default-devtools.timeline.frame',
        'toplevel',
        'blink.console',
        'blink.user_timing',
        'latencyInfo',
        'disabled-by-default-devtools.timeline.stack',
        'disabled-by-default-v8.cpu_profiler',
        'disabled-by-default-v8.cpu_profiler.hires'
      ]

      # @param {string} handle
      # @param {?string} path
      #
      def read_stream(handle, path)
        eof = false
        file = nil

        if path
          file = File.open path, 'w'
        end

        result =  ''
        while !eof do
          response = await client.command Protocol::IO.read handle: handle
          eof = response["eof"]
          result << response["data"]
          if path
            file << response["data"]
          end
        end

        if path
          file.close
        end
        await client.command Protocol::IO.close handle: handle

        result
      end
  end
end
