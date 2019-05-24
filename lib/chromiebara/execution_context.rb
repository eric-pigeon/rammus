require 'chromiebara/js_handle'
require 'chromiebara/element_handle'

module Chromiebara
  # The class represents a context for JavaScript execution. A Page might hav
  # many execution contexts:
  #
  # * each frame has "default" execution context that is always created after
  # frame is attached to DOM. This context is returned by the
  # frame.execution_context method.
  #
  # * Extensions's content scripts create additional execution contexts.
  #
  # Besides pages, execution contexts can be found in workers.
  #
  class ExecutionContext
    include Promise::Await

    EVALUATION_SCRIPT_URL = '__puppeteer_evaluation_script__';
    SOURCE_URL_REGEX = /^[\040\t]*\/\/[@#] sourceURL=\s*(\S*?)\s*$/m;

    attr_reader :client, :world, :context_id

    # @param [Chromiebara::CDPSession] client
    # @param [Protocol::Runtime::ExecutionContextDescription] context_payload
    # @param [Chromiebara::DOMWorld] world
    #
    def initialize(client, context_payload, world)
      @client = client
      @world = world
      @context_id = context_payload["id"]
    end

    # @return [Chromiebara::Frame, nil]
    #
    def frame
      world.nil? ? nil : world.frame
    end

    #  * @param {Function|string} pageFunction
    #  * @param {...*} args
    #  * @return {!Promise<(!Object|undefined)>}
    #  */
    def evaluate(page_function, *args, function: false)
      handle =
        if function
          evaluate_handle_function page_function, *args
        else
          evaluate_handle page_function, *args
        end
      result = handle.json_value
      # const result = await handle.jsonValue().catch(error => {
      #   if (error.message.includes('Object reference chain is too long'))
      #     return;
      #   if (error.message.includes('Object couldn\'t be returned by value'))
      #     return;
      #   throw error;
      # });
      handle.dispose
      result
    end

    def evaluate_handle_function(page_function, *args)
      suffix = "//# sourceURL=#{EVALUATION_SCRIPT_URL}"
      function_text = page_function

      arguments = args.map do |arg|
        if arg == Float::INFINITY then next { unserializableValue: 'Infinity' } end
        if arg == -Float::INFINITY then next { unserializableValue: '-Infinity' } end

        object_handle = arg && arg.is_a?(JSHandle) ? arg : nil
        if object_handle
          if object_handle.context != self
           raise 'JSHandles can be evaluated only in the context they were created!'
          end
          if object_handle.disposed?
            raise 'JSHandle is disposed!'
          end
          if object_handle.remote_object["unserializable_value"]
            raise 'TODO'
            # return { unserializableValue: objectHandle._remoteObject.unserializableValue };
          end
          if !object_handle.remote_object["objectId"]
            raise 'TODO'
          #  return { value: objectHandle._remoteObject.value };
          end
          next { objectId: object_handle.remote_object["objectId"] }
        end

        { value: arg }
        #   if (typeof arg === 'bigint') // eslint-disable-line valid-typeof
        #     return { unserializableValue: `${arg.toString()}n` };
        #   if (Object.is(arg, -0))
        #     return { unserializableValue: '-0' };
        #   if (Object.is(arg, Infinity))
        #     return { unserializableValue: 'Infinity' };
        #   if (Object.is(arg, -Infinity))
        #     return { unserializableValue: '-Infinity' };
        #   if (Object.is(arg, NaN))
        #     return { unserializableValue: 'NaN' };
      end

      response = await client.command(Protocol::Runtime.call_function_on(
        function_declaration: function_text + "\n" + suffix + "\n",
        execution_context_id: context_id,
        arguments: arguments,
        return_by_value: false,
        await_promise: true,
        user_gesture: true
      )).catch { |error| raise 'TODO' }

      if response["exceptionDetails"]
        # TODO
        raise 'FAILURE'
      end

      create_js_handle response["result"]

      # let callFunctionOnPromise;
      # try {
      #   callFunctionOnPromise = this._client.send('Runtime.callFunctionOn', {
      #     functionDeclaration: functionText + '\n' + suffix + '\n',
      #     executionContextId: this._contextId,
      #     arguments: args.map(convertArgument.bind(this)),
      #     returnByValue: false,
      #     awaitPromise: true,
      #     userGesture: true
      #   });
      # } catch (err) {
      #   if (err instanceof TypeError && err.message === 'Converting circular structure to JSON')
      #     err.message += ' Are you passing a nested JSHandle?';
      #   throw err;
      # }
      # const { exceptionDetails, result: remoteObject } = await callFunctionOnPromise.catch(rewriteError);
      # if (exceptionDetails)
      #   throw new Error('Evaluation failed: ' + helper.getExceptionMessage(exceptionDetails));
      # return createJSHandle(this, remoteObject);

      # /**
      #  * @param {*} arg
      #  * @return {*}
      #  * @this {ExecutionContext}
      #  */
      # function convertArgument(arg) {
      #   if (typeof arg === 'bigint') // eslint-disable-line valid-typeof
      #     return { unserializableValue: `${arg.toString()}n` };
      #   if (Object.is(arg, -0))
      #     return { unserializableValue: '-0' };
      #   if (Object.is(arg, Infinity))
      #     return { unserializableValue: 'Infinity' };
      #   if (Object.is(arg, -Infinity))
      #     return { unserializableValue: '-Infinity' };
      #   if (Object.is(arg, NaN))
      #     return { unserializableValue: 'NaN' };
      #   const objectHandle = arg && (arg instanceof JSHandle) ? arg : null;
      #   if (objectHandle) {
      #     if (objectHandle._context !== this)
      #       throw new Error('JSHandles can be evaluated only in the context they were created!');
      #     if (objectHandle._disposed)
      #       throw new Error('JSHandle is disposed!');
      #     if (objectHandle._remoteObject.unserializableValue)
      #       return { unserializableValue: objectHandle._remoteObject.unserializableValue };
      #     if (!objectHandle._remoteObject.objectId)
      #       return { value: objectHandle._remoteObject.value };
      #     return { objectId: objectHandle._remoteObject.objectId };
      #   }
      #   return { value: arg };
      # }
    end

    #  * @param {Function|string} pageFunction
    #  * @param {...*} args
    #  * @return {!Promise<!JSHandle>}
    #  */
    def evaluate_handle(page_function, *args)
      suffix = "//# sourceURL=#{EVALUATION_SCRIPT_URL}"

      expression_with_source_url = SOURCE_URL_REGEX.match?(page_function) ? page_function : page_function + "\n" + suffix;
      response = await client.command(Protocol::Runtime.evaluate(
        expression: expression_with_source_url,
        context_id: context_id,
        return_by_value: false,
        await_promise: true,
        user_gesture: true
      )).catch { |error| raise 'TODO '}

      if response["exceptionDetails"]
        # TODO
        raise 'FAILURE'
      end

      create_js_handle response["result"]
    end

    # /**
    #  * @param {!JSHandle} prototypeHandle
    #  * @return {!Promise<!JSHandle>}
    #  */
    # async queryObjects(prototypeHandle) {
    #   assert(!prototypeHandle._disposed, 'Prototype JSHandle is disposed!');
    #   assert(prototypeHandle._remoteObject.objectId, 'Prototype JSHandle must not be referencing primitive value');
    #   const response = await this._client.send('Runtime.queryObjects', {
    #     prototypeObjectId: prototypeHandle._remoteObject.objectId
    #   });
    #   return createJSHandle(this, response.objects);
    # }

    # /**
    #  * @param {Puppeteer.ElementHandle} elementHandle
    #  * @return {Promise<Puppeteer.ElementHandle>}
    #  */
    # async _adoptElementHandle(elementHandle) {
    #   assert(elementHandle.executionContext() !== this, 'Cannot adopt handle that already belongs to this execution context');
    #   assert(this._world, 'Cannot adopt handle without DOMWorld');
    #   const nodeInfo = await this._client.send('DOM.describeNode', {
    #     objectId: elementHandle._remoteObject.objectId,
    #   });
    #   const {object} = await this._client.send('DOM.resolveNode', {
    #     backendNodeId: nodeInfo.node.backendNodeId,
    #     executionContextId: this._contextId,
    #   });
    #   return /** @type {Puppeteer.ElementHandle}*/(createJSHandle(this, object));
    # }

    private

      # @param [Hash] remote_object
      #
      def create_js_handle(remote_object)
        if remote_object["subtype"] == "node" && frame
          frame_manager = frame.frame_manager
          return ElementHandle.new self, client, remote_object, frame_manager.page, frame_manager
        end

        JSHandle.new(self, self.client, remote_object)
      end

      #  * @param {!Error} error
      #  * @return {!Protocol.Runtime.evaluateReturnValue}
      #  */
      # function rewriteError(error) {
      #   if (error.message.endsWith('Cannot find context with specified id'))
      #     throw new Error('Execution context was destroyed, most likely because of a navigation.');
      #   throw error;
      # }
  end
end
