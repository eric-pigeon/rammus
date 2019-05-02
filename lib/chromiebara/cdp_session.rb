module Chromiebara
  class CDPSession
    attr_reader :client, :target_type, :session_id

    def initialize(client, target_type, session_id)
      @client = client
      @target_type = target_type
      @session_id = session_id
    end
  end
end
