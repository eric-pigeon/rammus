module Chromiebara
  module Protocol
    module Runtime
      extend self

      # Add handler to promise with given promise object id.
      #
      # @param promise_object_id [Remoteobjectid] Identifier of the promise.
      # @param return_by_value [Boolean] Whether the result is expected to be a JSON object that should be sent by value.
      # @param generate_preview [Boolean] Whether preview should be generated for the result.
      #
      def await_promise(promise_object_id:, return_by_value: nil, generate_preview: nil)
        {
          method: "Runtime.awaitPromise",
          params: { promiseObjectId: promise_object_id, returnByValue: return_by_value, generatePreview: generate_preview }.compact
        }
      end

      # Calls function with given declaration on the given object. Object group of the result is
      # inherited from the target object.
      #
      # @param function_declaration [String] Declaration of the function to call.
      # @param object_id [Remoteobjectid] Identifier of the object to call function on. Either objectId or executionContextId should be specified.
      # @param arguments [Array] Call arguments. All call arguments must belong to the same JavaScript world as the target object.
      # @param silent [Boolean] In silent mode exceptions thrown during evaluation are not reported and do not pause execution. Overrides `setPauseOnException` state.
      # @param return_by_value [Boolean] Whether the result is expected to be a JSON object which should be sent by value.
      # @param generate_preview [Boolean] Whether preview should be generated for the result.
      # @param user_gesture [Boolean] Whether execution should be treated as initiated by user in the UI.
      # @param await_promise [Boolean] Whether execution should `await` for resulting value and return once awaited promise is resolved.
      # @param execution_context_id [Executioncontextid] Specifies execution context which global object will be used to call function on. Either executionContextId or objectId should be specified.
      # @param object_group [String] Symbolic group name that can be used to release multiple objects. If objectGroup is not specified and objectId is, objectGroup will be inherited from object.
      #
      def call_function_on(function_declaration:, object_id: nil, arguments: nil, silent: nil, return_by_value: nil, generate_preview: nil, user_gesture: nil, await_promise: nil, execution_context_id: nil, object_group: nil)
        {
          method: "Runtime.callFunctionOn",
          params: { functionDeclaration: function_declaration, objectId: object_id, arguments: arguments, silent: silent, returnByValue: return_by_value, generatePreview: generate_preview, userGesture: user_gesture, awaitPromise: await_promise, executionContextId: execution_context_id, objectGroup: object_group }.compact
        }
      end

      # Compiles expression.
      #
      # @param expression [String] Expression to compile.
      # @param source_url [String] Source url to be set for the script.
      # @param persist_script [Boolean] Specifies whether the compiled script should be persisted.
      # @param execution_context_id [Executioncontextid] Specifies in which execution context to perform script run. If the parameter is omitted the evaluation will be performed in the context of the inspected page.
      #
      def compile_script(expression:, source_url:, persist_script:, execution_context_id: nil)
        {
          method: "Runtime.compileScript",
          params: { expression: expression, sourceURL: source_url, persistScript: persist_script, executionContextId: execution_context_id }.compact
        }
      end

      # Disables reporting of execution contexts creation.
      #
      def disable
        {
          method: "Runtime.disable"
        }
      end

      # Discards collected exceptions and console API calls.
      #
      def discard_console_entries
        {
          method: "Runtime.discardConsoleEntries"
        }
      end

      # Enables reporting of execution contexts creation by means of `executionContextCreated` event.
      # When the reporting gets enabled the event will be sent immediately for each existing execution
      # context.
      #
      def enable
        {
          method: "Runtime.enable"
        }
      end

      # Evaluates expression on global object.
      #
      # @param expression [String] Expression to evaluate.
      # @param object_group [String] Symbolic group name that can be used to release multiple objects.
      # @param include_command_line_api [Boolean] Determines whether Command Line API should be available during the evaluation.
      # @param silent [Boolean] In silent mode exceptions thrown during evaluation are not reported and do not pause execution. Overrides `setPauseOnException` state.
      # @param context_id [Executioncontextid] Specifies in which execution context to perform evaluation. If the parameter is omitted the evaluation will be performed in the context of the inspected page.
      # @param return_by_value [Boolean] Whether the result is expected to be a JSON object that should be sent by value.
      # @param generate_preview [Boolean] Whether preview should be generated for the result.
      # @param user_gesture [Boolean] Whether execution should be treated as initiated by user in the UI.
      # @param await_promise [Boolean] Whether execution should `await` for resulting value and return once awaited promise is resolved.
      # @param throw_on_side_effect [Boolean] Whether to throw an exception if side effect cannot be ruled out during evaluation.
      # @param timeout [Timedelta] Terminate execution after timing out (number of milliseconds).
      #
      def evaluate(expression:, object_group: nil, include_command_line_api: nil, silent: nil, context_id: nil, return_by_value: nil, generate_preview: nil, user_gesture: nil, await_promise: nil, throw_on_side_effect: nil, timeout: nil)
        {
          method: "Runtime.evaluate",
          params: { expression: expression, objectGroup: object_group, includeCommandLineAPI: include_command_line_api, silent: silent, contextId: context_id, returnByValue: return_by_value, generatePreview: generate_preview, userGesture: user_gesture, awaitPromise: await_promise, throwOnSideEffect: throw_on_side_effect, timeout: timeout }.compact
        }
      end

      # Returns the isolate id.
      #
      def get_isolate_id
        {
          method: "Runtime.getIsolateId"
        }
      end

      # Returns the JavaScript heap usage.
      # It is the total usage of the corresponding isolate not scoped to a particular Runtime.
      #
      def get_heap_usage
        {
          method: "Runtime.getHeapUsage"
        }
      end

      # Returns properties of a given object. Object group of the result is inherited from the target
      # object.
      #
      # @param object_id [Remoteobjectid] Identifier of the object to return properties for.
      # @param own_properties [Boolean] If true, returns properties belonging only to the element itself, not to its prototype chain.
      # @param accessor_properties_only [Boolean] If true, returns accessor properties (with getter/setter) only; internal properties are not returned either.
      # @param generate_preview [Boolean] Whether preview should be generated for the results.
      #
      def get_properties(object_id:, own_properties: nil, accessor_properties_only: nil, generate_preview: nil)
        {
          method: "Runtime.getProperties",
          params: { objectId: object_id, ownProperties: own_properties, accessorPropertiesOnly: accessor_properties_only, generatePreview: generate_preview }.compact
        }
      end

      # Returns all let, const and class variables from global scope.
      #
      # @param execution_context_id [Executioncontextid] Specifies in which execution context to lookup global scope variables.
      #
      def global_lexical_scope_names(execution_context_id: nil)
        {
          method: "Runtime.globalLexicalScopeNames",
          params: { executionContextId: execution_context_id }.compact
        }
      end

      # @param prototype_object_id [Remoteobjectid] Identifier of the prototype to return objects for.
      # @param object_group [String] Symbolic group name that can be used to release the results.
      #
      def query_objects(prototype_object_id:, object_group: nil)
        {
          method: "Runtime.queryObjects",
          params: { prototypeObjectId: prototype_object_id, objectGroup: object_group }.compact
        }
      end

      # Releases remote object with given id.
      #
      # @param object_id [Remoteobjectid] Identifier of the object to release.
      #
      def release_object(object_id:)
        {
          method: "Runtime.releaseObject",
          params: { objectId: object_id }.compact
        }
      end

      # Releases all remote objects that belong to a given group.
      #
      # @param object_group [String] Symbolic object group name.
      #
      def release_object_group(object_group:)
        {
          method: "Runtime.releaseObjectGroup",
          params: { objectGroup: object_group }.compact
        }
      end

      # Tells inspected instance to run if it was waiting for debugger to attach.
      #
      def run_if_waiting_for_debugger
        {
          method: "Runtime.runIfWaitingForDebugger"
        }
      end

      # Runs script with given id in a given context.
      #
      # @param script_id [Scriptid] Id of the script to run.
      # @param execution_context_id [Executioncontextid] Specifies in which execution context to perform script run. If the parameter is omitted the evaluation will be performed in the context of the inspected page.
      # @param object_group [String] Symbolic group name that can be used to release multiple objects.
      # @param silent [Boolean] In silent mode exceptions thrown during evaluation are not reported and do not pause execution. Overrides `setPauseOnException` state.
      # @param include_command_line_api [Boolean] Determines whether Command Line API should be available during the evaluation.
      # @param return_by_value [Boolean] Whether the result is expected to be a JSON object which should be sent by value.
      # @param generate_preview [Boolean] Whether preview should be generated for the result.
      # @param await_promise [Boolean] Whether execution should `await` for resulting value and return once awaited promise is resolved.
      #
      def run_script(script_id:, execution_context_id: nil, object_group: nil, silent: nil, include_command_line_api: nil, return_by_value: nil, generate_preview: nil, await_promise: nil)
        {
          method: "Runtime.runScript",
          params: { scriptId: script_id, executionContextId: execution_context_id, objectGroup: object_group, silent: silent, includeCommandLineAPI: include_command_line_api, returnByValue: return_by_value, generatePreview: generate_preview, awaitPromise: await_promise }.compact
        }
      end

      # Enables or disables async call stacks tracking.
      #
      # @param max_depth [Integer] Maximum depth of async call stacks. Setting to `0` will effectively disable collecting async call stacks (default).
      #
      def set_async_call_stack_depth(max_depth:)
        {
          method: "Runtime.setAsyncCallStackDepth",
          params: { maxDepth: max_depth }.compact
        }
      end

      def set_custom_object_formatter_enabled(enabled:)
        {
          method: "Runtime.setCustomObjectFormatterEnabled",
          params: { enabled: enabled }.compact
        }
      end

      def set_max_call_stack_size_to_capture(size:)
        {
          method: "Runtime.setMaxCallStackSizeToCapture",
          params: { size: size }.compact
        }
      end

      # Terminate current or next JavaScript execution.
      # Will cancel the termination when the outer-most script execution ends.
      #
      def terminate_execution
        {
          method: "Runtime.terminateExecution"
        }
      end

      # If executionContextId is empty, adds binding with the given name on the
      # global objects of all inspected contexts, including those created later,
      # bindings survive reloads.
      # If executionContextId is specified, adds binding only on global object of
      # given execution context.
      # Binding function takes exactly one argument, this argument should be string,
      # in case of any other input, function throws an exception.
      # Each binding function call produces Runtime.bindingCalled notification.
      #
      def add_binding(name:, execution_context_id: nil)
        {
          method: "Runtime.addBinding",
          params: { name: name, executionContextId: execution_context_id }.compact
        }
      end

      # This method does not remove binding function from global object but
      # unsubscribes current runtime agent from Runtime.bindingCalled notifications.
      #
      def remove_binding(name:)
        {
          method: "Runtime.removeBinding",
          params: { name: name }.compact
        }
      end
    end
  end
end
