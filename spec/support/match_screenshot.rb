require 'chunky_png'

module MatchScreenshot
  def match_screenshot(expected_filename)
    MatchScreenshotMatcher.new(expected_filename)
  end

  class MatchScreenshotMatcher
    THRESHOLD = 0.1

    include ChunkyPNG::Color

    def initialize(expected_filename)
      @expected_filename = expected_filename
    end

    def matches?(actual_buffer)
      @actual_buffer = actual_buffer

      return false unless actual.width == expected.width && actual.height == expected.height

      @diff = []
      output = ChunkyPNG::Image.new(expected.width, expected.height, ChunkyPNG::Color::WHITE)

      expected.height.times do |y|
        expected.row(y).each_with_index do |pixel, x|
          unless pixel == actual[x,y]
            score = Math.sqrt(
              (ChunkyPNG::Color.r(actual[x,y]) - ChunkyPNG::Color.r(pixel)) ** 2 +
              (ChunkyPNG::Color.g(actual[x,y]) - ChunkyPNG::Color.g(pixel)) ** 2 +
              (ChunkyPNG::Color.b(actual[x,y]) - ChunkyPNG::Color.b(pixel)) ** 2
            ) / Math.sqrt(ChunkyPNG::Color::MAX ** 2 * 3)

            output[x,y] = ChunkyPNG::Color.grayscale(ChunkyPNG::Color::MAX - (score * 255).round)
            @diff << score if score >= THRESHOLD
          end
        end
      end

      @save_path = File.expand_path("../../", __FILE__) + "/" + "ugh.png"
      output.save @save_path unless @diff.empty?

      @diff.empty?
    end

    def failure_message
      if actual.width != expected.width
        return "Expected screenshot width to equal #{expected_with} but was #{actual_width}"
      end
      if actual.height != expected.height
        return "Expected screenshot height to equal #{expected_with} but was #{actual_width}"
      end

      <<~MESSAGE
      Expected screenshot to match #{expected_path}\n
      Difference image saved to #{@save_path}
      MESSAGE
    end

    private

      def expected
        @_expected ||= ChunkyPNG::Image.from_file expected_path
      end

      def actual
        @_actual ||= ChunkyPNG::Image.from_datastream ChunkyPNG::Datastream.from_string @actual_buffer
      end

      def expected_path
        @_expected_path ||= File.expand_path("../../fixtures", __FILE__) + "/" + @expected_filename
      end

      def expected_with
        expected_image.width
      end

      def expected_height
        expected_image.height
      end
  end
end
