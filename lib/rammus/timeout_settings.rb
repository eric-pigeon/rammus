module Rammus
  # @!visibility private
  class TimeoutSettings
    attr_accessor :timeout

    def initialize
      @timeout = DEFAULT_TIMEOUT
      @_navigation_timeout = nil
    end

    def set_default_navigation_timeout(timeout)
      @_navigation_timeout = timeout
    end

    def navigation_timeout
      @_navigation_timeout || timeout || DEFAULT_TIMEOUT
    end

    private

      DEFAULT_TIMEOUT = 2
  end
end