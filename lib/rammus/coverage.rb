require 'rammus/js_coverage'
require 'rammus/css_coverage'

module Rammus
  # Coverage gathers information about parts of JavaScript and CSS that were used by the page.
  #
  # # TODO verify this example
  # @example Using JavaScript and CSS coverage to get percentage of initially executed code
  #    # Enable both JavaScript and CSS coverage
  #    page.coverage.start_js_coverage
  #    page.coverage.start_css_coverage
  #
  #    # Navigate to page
  #    await page.goto 'https://example.com'
  #    # Disable both JavaScript and CSS coverage
  #    js_Coverage = page.coverage.stop_js_coverage
  #    css_coverage = page.coverage.stop_css_coverage
  #
  #    total_bytes = 0
  #    used_bytes = 0
  #    coverage = js_coverage + css_coverage
  #    coverage.each do |entry|
  #      total_bytes += entry.text.length
  #      entry.ranges.each do |range|
  #        used_bytes += range.end - range.start - 1
  #      end
  #    endk
  #    puts "Bytes used: #{used_bytes / total_bytes * 100}%"
  #
  class Coverage
    # @param [Rammus::CDPSession] client
    #
    # @!visibility private
    #
    def initialize(client)
      @_js_coverage = JSCoverage.new client
      @_css_coverage = CSSCoverage.new client
    end

    # (see Rammus::JSCoverage#start)
    #
    def start_js_coverage(reset_on_navigation: true, report_anonymous_scripts: nil)
      @_js_coverage.start reset_on_navigation: reset_on_navigation, report_anonymous_scripts: report_anonymous_scripts
      nil
    end

    # (see Rammus::JSCoverage#stop)
    #
    def stop_js_coverage
      @_js_coverage.stop
    end

    # (see Rammus::CSSCoverage#start)
    #
    def start_css_coverage(reset_on_navigation: true)
      @_css_coverage.start reset_on_navigation: reset_on_navigation
    end

    # (see Rammus::CSSCoverage#stop)
    #
    def stop_css_coverage
      @_css_coverage.stop
    end

    # @!visibility private
    #
    # @param nested_ranges [!Array<!{startOffset:number, endOffset:number, count:number}>} nestedRanges
    #
    # @return [Array<Hash{start => number, end => number}>]
    #
    def self.convert_to_disjoint_ranges(nested_ranges)
      points = nested_ranges.flat_map do |range|
        [{ offset: range["startOffset"], type: 0, range: range },
         { offset: range["endOffset"], type: 1, range: range }]
      end

      # Sort points to form a valid parenthesis sequence.
      points.sort! do |a, b|
        # Sort with increasing offsets.
        next a[:offset] - b[:offset] if a[:offset] != b[:offset]
        # All "end" points should go before "start" points.
        next b[:type] - a[:type] if a[:type] != b[:type]
        a_length = a[:range]["endOffset"] - a[:range]["startOffset"]
        b_length = b[:range]["endOffset"] - b[:range]["startOffset"]
        # For two "start" points, the one with longer range goes first.
        next b_length - a_length if a[:type].zero?
        # For two "end" points, the one with shorter range goes first.
        a_length - b_length
      end

      hit_count_stack = []
      results = []
      last_offset = 0
      # Run scanning line to intersect all ranges.
      points.each do |point|
        #if (hitCountStack.length && lastOffset < point.offset && hitCountStack[hitCountStack.length - 1] > 0) {
        if hit_count_stack.length > 0 && last_offset < point[:offset] && hit_count_stack.last > 0
          last_result = results.last
          if last_result && last_result[:end] == last_offset
            last_result[:end] = point[:offset]
          else
            results << { start: last_offset, end: point[:offset] }
          end
        end
        last_offset = point[:offset]
        if point[:type].zero?
          hit_count_stack << point[:range]["count"]
        else
          hit_count_stack.pop
        end
      end
      # Filter out empty ranges.
      results.select { |range| range[:end] - range[:start] > 1 }
    end
  end
end
