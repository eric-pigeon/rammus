module Rammus
  # Dialog objects are dispatched by page via the 'dialog' event.
  #
  # An example of using Dialog class:
  #
  class Dialog
    include Promise::Await

    ALERT = :alert
    BEFORE_UNLOAD = :beforeunload
    CONFIRM = :confirm
    PROMPT = :prompt

    # @return [String] Dialog's type, can be one of alert, beforeunload, confirm or prompt.
    #
    attr_reader :type

    # @return [String] A message displayed in the dialog.
    #
    attr_reader :message

    # @return [String] If dialog is prompt, returns default prompt value. Otherwise, returns empty string.
    #
    attr_reader :default_value

    # @!visibility private
    #
    # @param client [Rammus::CDPSession]
    # @param type [String]
    # @param message [String]
    # @param default_value [String, nil]
    #
    #
    def initialize(client, type, message, default_value = '')
      @_client = client
      @type = type
      @message = message
      @default_value = default_value
      @_handled = false
    end

    # @param prompt_text [String]
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
