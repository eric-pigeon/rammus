module Rammus
  module Errors
    class Error < StandardError; end

    class ProtocolError < Error; end
    class TimeoutError < Error; end
    class PageCrashed < Error; end
    class UncloseableContext < Error; end
  end
end
