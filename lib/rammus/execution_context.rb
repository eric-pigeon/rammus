# frozen_string_literal: true

require 'rammus/js_handle'
require 'rammus/element_handle'

module Rammus
  # The class represents a context for JavaScript execution. A Page might hav
  # many execution contexts:
  #
  # * each frame has "default" execution context that is always created after frame is attached to DOM. This context is returned by the frame.execution_context method.
  #
  # * Extensions's content scripts create additional execution contexts.
  #
  # Besides pages, execution contexts can be found in workers.
  #
  class ExecutionContext
    # @!visibility private
    #
    EVALUATION_SCRIPT_URL = '__puppeteer_evaluation_script__'
    # @!visibility private
    #
    SOURCE_URL_REGEX = %r{^[\040\t]*//[@#] sourceURL=\s*(\S*?)\s*$}m.freeze
    # @!visibility private
    #
    SUFFIX = "//# sourceURL=#{EVALUATION_SCRIPT_URL}"

    attr_reader :client, :world, :context_id

    # @!visibility private
    #
    # @param client [Rammus::CDPSession]
    # @param context_payload [Protocol::Runtime::ExecutionContextDescription]
    # @param world [Rammus::DOMWorld]
    #
    def initialize(client, context_payload, world)
      @client = client
      @world = world
      @context_id = context_payload["id"]
    end

    # Frame associated with this execution context.
    #
    # Not every execution context is associated with a frame. For example,
    # workers and extensions have execution contexts that are not associated with frames.
    #
    # @return [Rammus::Frame, nil]
    #
    def frame
      world.nil? ? nil : world.frame
    end

    # Evaluates the string and returns the result.  If the javascript is a
    # function call use {evaluate_function} instead.
    #
    # @param javascript [String]
    #
    # @return [Promise<Object,nil>]
    #
    def evaluate(javascript)
      evaluate_internal true, javascript
    end

    # Evaluates the javascript function call and returns the results.
    # If the function passed to the {evaluate_function} returns a Promise,
    # then {evaluate_function} would wait for the promise to resolve and return
    # its value.
    #
    # If the function passed to the {evaluate} returns a non-Serializable value,
    # then {evaluate} resolves to undefined. DevTools Protocol also supports
    # transferring some additional values that are not serializable by
    # JSON: -0, NaN, Infinity, -Infinity, and bigint literals.
    #
    # @param page_function [String] Function to be evaluated in the page context
    # @param args [Array<Serializable,JsHandle>] Arguments to pass to page_function
    #
    # @return [Promise<Object,nil>]
    #
    def evaluate_function(page_function, *args)
      evaluate_function_internal true, page_function, *args
    end

    # Evaluates the string and returns the result.  The only difference between
    # {evaluate} and {evaluate_handle} is that {evaluate_handle} returns an
    # in-page object({Rammus::JsHandle}.
    #
    # If the javascript is a function call use {evaluate_handle_function} instead.
    #
    # @param javascript [String]
    #
    # @return [Promise<Rammus::JSHandle>]
    #
    def evaluate_handle(javascript)
      evaluate_internal false, javascript
    end

    # Evaluates the javascript function call and returns the results.
    # If the function passed to the {evaluate_function} returns a Promise,
    # then {evaluate_function} would wait for the promise to resolve and return
    # its value.
    #
    # If the function passed to the {evaluate} returns a non-Serializable value,
    # then {evaluate} resolves to undefined. DevTools Protocol also supports
    # transferring some additional values that are not serializable by
    # JSON: -0, NaN, Infinity, -Infinity, and bigint literals.
    #
    # The only difference between {evaluate_function} and
    # {evaluate_handle_function} is that {evaluate_handle_function} returns an
    # in-page object({Rammus::JsHandle}.
    #
    # @param page_function [String] Function to be evaluated in the page context
    # @param args [Array<Serializable,JsHandle>] Arguments to pass to page_function
    #
    # @return [Promise<Rammus::JSHandle>]
    #
    def evaluate_handle_function(page_function, *args)
      evaluate_function_internal false, page_function, *args
    end

    # The method iterates the JavaScript heap and finds all the objects with
    # the given prototype.
    #
    # @example
    #   await page.evaluate_function "() => window.map = new Map()"
    #   # Get a handle to the Map object prototype
    #   map_prototype = await page.evaluate_handle_function "() => Map.prototype"
    #   # Query all map instances into an array
    #   map_instances = await page.query_objects map_prototype
    #   # Count amount of map objects in heap
    #   count = await page.evaluate_function "maps => maps.length", map_instances
    #   await map_instances.dispose
    #   await map_prototype.dispose
    #
    # @param prototype_handle [Rammus::JSHandle]
    #
    # @return [Rammus::JSHandle]
    #
    def query_objects(prototype_handle)
      raise 'Prototype JSHandle is disposed!' if prototype_handle.disposed?
      raise 'Prototype JSHandle must not be referencing primitive value' if prototype_handle.remote_object["objectId"].nil?

      response = client.command(Protocol::Runtime.query_objects(prototype_object_id: prototype_handle.remote_object["objectId"])).value!
      JSHandle.create_js_handle self, response["objects"]
    end

    # @!visibility private
    #
    # @param element_handle [Rammus::ElementHandle]
    #
    # @return [Rammus::ElementHandle]
    #
    def _adopt_element_handle(element_handle)
      'Cannot adopt handle that already belongs to this execution context' if element_handle.execution_context == self
      'Cannot adopt handle without DOMWorld' if world.nil?
      node_info = client.command(Protocol::DOM.describe_node(object_id: element_handle.remote_object["objectId"])).value!
      object = client.command(Protocol::DOM.resolve_node(backend_node_id: node_info["node"]["backendNodeId"], execution_context_id: context_id)).value!
      JSHandle.create_js_handle self, object["object"]
    end

    private

      def evaluate_internal(return_by_value, expression)
        expression = SOURCE_URL_REGEX.match?(expression) ? expression : "#{expression}\n#{SUFFIX}"
        evaluate_promise = client.command(
          Protocol::Runtime.evaluate(
            expression: expression,
            context_id: context_id,
            return_by_value: return_by_value,
            await_promise: true,
            user_gesture: true
          )
        ).rescue(&method(:rewrite_error))

        evaluate_promise.then do |response|
          if response["exceptionDetails"]
            raise "Evaluation failed: #{Util.get_exception_message response['exceptionDetails']}"
          end

          if return_by_value
            Util.value_from_remote_object response["result"]
          else
            JSHandle.create_js_handle self, response["result"]
          end
        end
      end

      def evaluate_function_internal(return_by_value, function_text, *args)
        call_function_on_promise =
          begin
            client.command(
              Protocol::Runtime.call_function_on(
                function_declaration: function_text + "\n" + SUFFIX + "\n",
                execution_context_id: context_id,
                arguments: args.map { |arg| convert_argument arg },
                return_by_value: return_by_value,
                await_promise: true,
                user_gesture: true
              )
            ).rescue(&method(:rewrite_error))
          rescue => err
            #  if (err instanceof TypeError && err.message === 'Converting circular structure to JSON')
            #    err.message += ' Are you passing a nested JSHandle?';
            raise err
          end

        call_function_on_promise.then do |response|
          if response["exceptionDetails"]
            raise "Evaluation failed: #{Util.get_exception_message response['exceptionDetails']}"
          end

          if return_by_value
            Util.value_from_remote_object response["result"]
          else
            JSHandle.create_js_handle self, response["result"]
          end
        end
      end

      def convert_argument(arg)
        # if (typeof arg === 'bigint') // eslint-disable-line valid-typeof
        #  return { unserializableValue: `${arg.toString()}n` };
        if arg == Float::INFINITY
          return { unserializableValue: 'Infinity' }
        end
        if arg == -Float::INFINITY
          return { unserializableValue: '-Infinity' }
        end
        if arg.is_a?(Float) && arg.nan?
          return { unserializableValue: 'NaN' }
        end

        object_handle = arg&.is_a?(JSHandle) ? arg : nil
        if object_handle
          if object_handle.context != self
            raise 'JSHandles can be evaluated only in the context they were created!'
          end
          if object_handle.disposed?
            raise 'JSHandle is disposed!'
          end
          if object_handle.remote_object["unserializableValue"]
            return { unserializableValue: object_handle.remote_object["unserializableValue"] }
          end
          unless object_handle.remote_object["objectId"]
            return { value: object_handle.remote_object["value"] }
          end

          return { objectId: object_handle.remote_object["objectId"] }
        end
        { value: arg }
      end

      def rewrite_error(error)
        if error.message.include? 'Object reference chain is too long'
          return { "result" => { "type" => 'undefined' } }
        end

        if error.message.include? "Object couldn't be returned by value"
          return { "result" => { "type" => 'undefined' } }
        end

        if error.message.end_with? 'Cannot find context with specified id'
          raise 'Execution context was destroyed, most likely because of a navigation.'
        end

        throw error
      end
  end
end
