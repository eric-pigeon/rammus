module Chromiebara
  class Promise
    def initialize
    end

    private

      def current_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
  end
end
