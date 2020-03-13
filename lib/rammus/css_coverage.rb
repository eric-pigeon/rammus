module Rammus
  # @!visibility private
  #
  class CSSCoverage
    attr_reader :client

    # @param client [Rammus::CDPSession]
    #
    def initialize(client)
      @client = client
      @_enabled = false
      @_stylesheet_urls = {}
      @_stylesheet_sources = {}
      @_event_listeners = []
      @_reset_on_navigation = false
    end

    # @param reset_on_navigation [Boolean] Whether to reset coverage on every
    #   navigation. Defaults to true.
    #
    # @return [nil]
    #
    def start(reset_on_navigation: true)
      raise 'CSSCoverage is already enabled' if @_enabled
      @_reset_on_navigation = reset_on_navigation
      @_enabled = true
      @_stylesheet_urls.clear
      @_stylesheet_sources.clear
      @_event_listeners = [
        Util.add_event_listener(client, Protocol::CSS.style_sheet_added, method(:on_style_sheet)),
        Util.add_event_listener(client, Protocol::Runtime.execution_contexts_cleared, method(:on_execution_contexts_cleared))
      ]
      Concurrent::Promises.zip(
        client.command(Protocol::DOM.enable),
        client.command(Protocol::CSS.enable),
        client.command(Protocol::CSS.start_rule_usage_tracking),
      ).wait!
      nil
    end

    # Get coverage report
    #
    # @return [Array<Hash<url: String, text: String, ranges: Array<Hash<start: Integer, stop: Integer>>>]
    #
    def stop
      raise 'CSSCoverage is not enabled' unless @_enabled
      @_enabled = false
      rule_tracking_response = client.command(Protocol::CSS.stop_rule_usage_tracking).value!
      Concurrent::Promises.zip(
        client.command(Protocol::CSS.disable),
        client.command(Protocol::DOM.disable),
      ).wait!
      Util.remove_event_listeners @_event_listeners

      # aggregate by styleSheetId
      style_sheet_id_to_coverage = Hash.new { |hash, key| hash[key] = [] }
      rule_tracking_response["ruleUsage"].each do |entry|
        ranges = style_sheet_id_to_coverage[entry["styleSheetId"]]
        ranges << {
          "startOffset" => entry["startOffset"],
          "endOffset" => entry["endOffset"],
          "count" => entry["used"] ? 1 : 0,
        }
      end

      coverage = []
      @_stylesheet_urls.each do |style_sheet_id, url|
        text = @_stylesheet_sources[style_sheet_id]
        ranges = Coverage.convert_to_disjoint_ranges(style_sheet_id_to_coverage[style_sheet_id] || [])
        coverage << { url: url, ranges: ranges, text: text }
      end

      coverage
    end

    private

      def on_execution_contexts_cleared(_event)
        return unless @_reset_on_navigation
        @_stylesheet_urls.clear
        @_stylesheet_sources.clear
      end

      def on_style_sheet(event)
        header = event["header"]
        # Ignore anonymous scripts
        return if header["sourceURL"] == ""
        begin
          response = client.command(Protocol::CSS.get_style_sheet_text(style_sheet_id: header["styleSheetId"])).value!
          @_stylesheet_urls[header["styleSheetId"]] = header["sourceURL"]
          @_stylesheet_sources[header["styleSheetId"]] = response["text"]
        rescue => error
          # This might happen if the page has already navigated away.
          Util.debug_error error
        end
      end
  end
end
