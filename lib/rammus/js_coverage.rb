module Rammus
  class JSCoverage
    include Promise::Await

    attr_reader :client

    # @!visibility private
    #
    # @param client [Rammus::CDPSession]
    #
    def initialize(client)
      @client = client
      @_enabled = false
      @_script_urls = {}
      @_script_sources = {}
      @_event_listeners = []
      @_reset_on_navigation = false
      @_report_anonymous_scripts = false
    end

    def start(reset_on_navigation: true, report_anonymous_scripts: false)
      raise 'JSCoverage is already enabled' if @_enabled
      @_reset_on_navigation = reset_on_navigation
      @_report_anonymous_scripts = report_anonymous_scripts
      @_enabled = true
      @_script_urls.clear
      @_script_sources.clear
      @_event_listeners = [
        Util.add_event_listener(client, Protocol::Debugger.script_parsed, method(:on_script_parsed)),
        Util.add_event_listener(client, Protocol::Runtime.execution_contexts_cleared, method(:on_execution_contexts_cleared))
      ]
      await Promise.all(
        client.command(Protocol::Profiler.enable),
        client.command(Protocol::Profiler.start_precise_coverage call_count: false, detailed: true),
        client.command(Protocol::Debugger.enable),
        client.command(Protocol::Debugger.set_skip_all_pauses skip: true)
      )
    end

    # @return {!Promise<!Array<!CoverageEntry>>}
    #
    def stop
      raise 'JSCoverage is not enabled' unless @_enabled
      @_enabled = false
      profile_response, _ = await Promise.all(
        @client.command(Protocol::Profiler.take_precise_coverage),
        @client.command(Protocol::Profiler.stop_precise_coverage),
        @client.command(Protocol::Profiler.disable),
        @client.command(Protocol::Debugger.disable),
      )
      Util.remove_event_listeners @_event_listeners

      coverage = []
      profile_response["result"].each do |entry|
        url = @_script_urls[entry["scriptId"]]
        if url == "" && @_report_anonymous_scripts
          url = 'debugger://VM' + entry["scriptId"]
        end
        text = @_script_sources[entry["scriptId"]]

        next if text.nil? || url.nil?

        flatten_ranges = entry["functions"].flat_map { |func| func["ranges"] }
        ranges = Coverage.convert_to_disjoint_ranges flatten_ranges
        coverage << { url: url, ranges: ranges, text: text }
      end
      coverage
    end

    private

      # @param {!Protocol.Debugger.scriptParsedPayload} event
      #
      def on_script_parsed(event)
        # Ignore puppeteer-injected scripts
        return if event["url"] == ExecutionContext::EVALUATION_SCRIPT_URL
        # Ignore other anonymous scripts unless the report_anonymous_scripts option is true.
        return if event["url"] == "" && !@_report_anonymous_scripts

        begin
          response = await client.command Protocol::Debugger.get_script_source(script_id: event["scriptId"])
          @_script_urls[event["scriptId"]] = event["url"]
          @_script_sources[event["scriptId"]] = response["scriptSource"]
        rescue => error
          # This might happen if the page has already navigated away.
          Util.debug_error error
        end
      end

      def on_execution_contexts_cleared(_event)
        return unless @_reset_on_navigation
        @_script_urls.clear
        @_script_sources.clear
      end
  end
end
