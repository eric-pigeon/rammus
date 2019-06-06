module Chromiebara
  class Worker
    include Promise::Await

    attr_reader :url

    # @param {Puppeteer.CDPSession} client
    # @param {string} url
    # @param {function(string, !Array<!JSHandle>, Protocol.Runtime.StackTrace=):void} consoleAPICalled
    # @param {function(!Protocol.Runtime.ExceptionDetails):void} exceptionThrown
    #
    def initialize(client, url, console_api_called = nil, exception_thrown = nil)
      # super();
      @_client = client
      @url = url
      @_execution_context_promise, @_execution_context_callback = Promise.create
      # @type {function(!Protocol.Runtime.RemoteObject):!JSHandle}
      @_js_Handle_factory = nil
      client.once Protocol::Runtime.execution_context_created, method(:on_execution_context_created)
      # // This might fail if the target is closed before we recieve all execution contexts.
      @_client.command Protocol::Runtime.enable

      # this._client.on('Runtime.consoleAPICalled', event => consoleAPICalled(event.type, event.args.map(jsHandleFactory), event.stackTrace));
      # this._client.on('Runtime.exceptionThrown', exception => exceptionThrown(exception.exceptionDetails));
    end

    def execution_context
      await @_execution_context_promise
    end

    # @param {Function|string} pageFunction
    # @param {!Array<*>} args
    # @return {!Promise<*>}
    #
    #async evaluate(pageFunction, ...args) {
    #  return (await this._executionContextPromise).evaluate(pageFunction, ...args);
    #}

    def evaluate_function(page_function, *args)
      execution_context.evaluate_function page_function, *args
    end

    # @param {Function|string} pageFunction
    # @param {!Array<*>} args
    # @return {!Promise<!JSHandle>}
    #
    #async evaluateHandle(pageFunction, ...args) {
    #  return (await this._executionContextPromise).evaluateHandle(pageFunction, ...args);
    #}

    def evaluate_handle_function(page_function, *args)
      execution_context.evaluate_handle_function page_function, *args
      #TODO
    end

    private

      def on_execution_context_created(event)
        # jsHandleFactory = remoteObject => new JSHandle(executionContext, client, remoteObject);
        execution_context = ExecutionContext.new @_client, event["context"], nil
        @_execution_context_callback.(execution_context)
      end
  end
end
