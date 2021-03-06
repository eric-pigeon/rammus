# frozen_string_literal: true

module Rammus
  class Worker
    attr_reader :url

    # @param {Puppeteer.CDPSession} client
    # @param {string} url
    # @param {function(string, !Array<!JSHandle>, Protocol.Runtime.StackTrace=):void} consoleAPICalled
    # @param {function(!Protocol.Runtime.ExceptionDetails):void} exceptionThrown
    #
    def initialize(client, url, console_api_called, exception_thrown)
      # super();
      @_client = client
      @url = url
      @_execution_context_promise = Concurrent::Promises.resolvable_future
      @_execution_context_callback = @_execution_context_promise.method(:fulfill)
      # @type {function(!Protocol.Runtime.RemoteObject):!JSHandle}
      @_js_handle_factory = nil
      client.once Protocol::Runtime.execution_context_created, method(:on_execution_context_created)
      # // This might fail if the target is closed before we recieve all execution contexts.
      @_client.command Protocol::Runtime.enable

      @_client.on Protocol::Runtime.console_api_called, ->(event) { console_api_called.(event["type"], event["args"].map(&@_js_handle_factory), event["stackTrace"]) }
      @_client.on Protocol::Runtime.exception_thrown, ->(exception) { exception_thrown.(exception["exceptionDetails"]) }
    end

    def execution_context
      @_execution_context_promise.value!
    end

    # @param {Function|string} pageFunction
    # @param {!Array<*>} args
    # @return {!Promise<*>}
    #
    # async evaluate(pageFunction, ...args) {
    #  return (await this._executionContextPromise).evaluate(pageFunction, ...args);
    # }

    def evaluate_function(page_function, *args)
      execution_context.evaluate_function page_function, *args
    end

    # @param {Function|string} pageFunction
    # @param {!Array<*>} args
    # @return {!Promise<!JSHandle>}
    #
    # async evaluateHandle(pageFunction, ...args) {
    #  return (await this._executionContextPromise).evaluateHandle(pageFunction, ...args);
    # }

    def evaluate_handle_function(page_function, *args)
      execution_context.evaluate_handle_function page_function, *args
      # TODO
    end

    private

      def on_execution_context_created(event)
        execution_context = ExecutionContext.new @_client, event["context"], nil
        @_js_handle_factory = ->(remote_object) { JSHandle.new execution_context, @_client, remote_object }
        @_execution_context_callback.(execution_context)
      end
  end
end
