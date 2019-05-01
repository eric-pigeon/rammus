module Chromiebara
  class FrameManager
    attr_reader :client, :page

    def initialize(client, page)
      @client = client
      @page = page
    end
  end
end
