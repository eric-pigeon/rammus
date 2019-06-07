require 'chromiebara/util'

module Chromiebara
  # JSHandle represents an in-page JavaScript object. JSHandles can be created
  # with the page.evaluateHandle method.
  #
  #
  # JSHandle prevents the referenced JavaScript object being garbage collected
  # unless the handle is disposed. JSHandles are auto-disposed when their origin
  # frame gets navigated or the parent context gets destroyed.
  #
  # JSHandle instances can be used as arguments in page.$eval(), page.evaluate()
  # and page.evaluateHandle methods.
  #
  class JSHandle
    include Promise::Await
    attr_reader :context, :client, :remote_object

    def self.create_js_handle(context, remote_object)
      frame = context.frame

      if remote_object["subtype"] == 'node' && frame
        frame_manager = frame.frame_manager
        return  ElementHandle.new context, context.client, remote_object, frame_manager.page, frame_manager
      end

      JSHandle.new context, context.client, remote_object
    end

    # @param [Chromiebara::ExecutionContext] context
    # @param [Chromiebara::CDPSession] client
    # @param [Protocol.Runtime.RemoteObject] remote_object
    def initialize(context, client, remote_object)
      @context = context
      @client = client
      @remote_object = remote_object
      @_disposed = false
    end

    # @return {!Puppeteer.ExecutionContext}
    #  */
    def execution_context
      @context
    end

    def disposed?
      @_disposed
    end

    # @param {string} propertyName
    # @return {!Promise<?JSHandle>}
    #
    def get_property(property_name)
      function = <<~JAVASCRIPT
      (object, propertyName) => {
        const result = {__proto__: null};
        result[propertyName] = object[propertyName];
        return result;
      }
      JAVASCRIPT
      object_handle = execution_context.evaluate_handle_function function, self, property_name
      properties = object_handle.get_properties
      result = properties[property_name]
      object_handle.dispose
      result
    end

    # @return {!Promise<!Map<string, !JSHandle>>}
    #
    def get_properties
      response = await client.command Protocol::Runtime.get_properties(
        object_id: remote_object["objectId"],
        own_properties: true
      )
      response["result"].each_with_object({}) do |property, memo|
        next unless property["enumerable"]

        memo[property["name"]] = JSHandle.create_js_handle context, property["value"]
      end
    end

    def json_value
      if remote_object["objectId"]
        response = await client.command Protocol::Runtime.call_function_on(
          function_declaration: 'function() { return this; }',
          object_id: remote_object["objectId"],
          return_by_value: true,
          await_promise: true
        )
        return Util.value_from_remote_object response["result"]
      end

      Util.value_from_remote_object remote_object
    end

    # @return {?Puppeteer.ElementHandle}
    #
    def as_element
      nil
    end

    def dispose
      return if @_disposed

      @_disposed = true
      if remote_object["objectId"]
        await client.command(Protocol::Runtime.release_object object_id: remote_object["objectId"]).catch do |error|
          # Exceptions might happen in case of a page been navigated or closed.
          # Swallow these since they are harmless and we don't leak anything in this case.
          # TODO warn about this
        end
      end
    end

    # @override
    # @return {string}
    #
    def to_s
      if remote_object["objectId"]
        type = remote_object["subtype"] || remote_object["type"]
        return "JSHandle@#{type}"
      end
      "JSHandle: #{Util.value_from_remote_object remote_object}"
    end
  end
end
