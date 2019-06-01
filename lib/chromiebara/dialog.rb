module Chromiebara
  class Dialog
    include Promise::Await

    ALERT = :alert
    BEFORE_UNLOAD = :beforeunload
    CONFIRM = :confirm
    PROMPT = :prompt

    attr_reader :type, :message, :default_value

    # @param {!Puppeteer.CDPSession} client
    # @param {string} type
    # @param {string} message
    # @param {(string|undefined)} default_value
    #
    def initialize(client, type, message, default_value = '')
      @_client = client
      @type = type
      @message = message
      @default_value = default_value
      @_handled = false
    end

    # @param {string=} prompt_text
    #
    def accept(prompt_text = nil)
      raise 'Cannot accept dialog which is already handled!' if @_handled
      @_handled = true
      await @_client.command Protocol::Page.handle_java_script_dialog accept: true, prompt_text: prompt_text
    end

    def dismiss
      raise 'Cannot dismiss dialog which is already handled!' if @_handled
      @_handled = true
      await @_client.command Protocol::Page.handle_java_script_dialog accept: false
    end
  end
end
