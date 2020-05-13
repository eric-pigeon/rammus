# frozen_string_literal: true

module Rammus
  # Dialog objects are dispatched by page via the 'dialog' event.
  #
  # An example of using Dialog class:
  #
  class Dialog
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
    # @return [nil]
    #
    def accept(prompt_text = nil)
      raise 'Cannot accept dialog which is already handled!' if @_handled

      @_handled = true
      @_client.command(Protocol::Page.handle_java_script_dialog(accept: true, prompt_text: prompt_text)).wait!
      nil
    end

    # @return [nil]
    #
    def dismiss
      raise 'Cannot dismiss dialog which is already handled!' if @_handled

      @_handled = true
      @_client.command(Protocol::Page.handle_java_script_dialog(accept: false)).wait!
      nil
    end
  end
end
