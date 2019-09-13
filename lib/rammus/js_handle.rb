require 'rammus/util'

module Rammus
  # JSHandle represents an in-page JavaScript object. JSHandles can be created
  # with the {Page.evaluate_handle} method.
  #
  # @example
  #    window_handle = await page.evaluate_handle 'window'
  #
  # JSHandle prevents the referenced JavaScript object being garbage collected
  # unless the handle is disposed. JSHandles are auto-disposed when their origin
  # frame gets navigated or the parent context gets destroyed.
  #
  # JSHandle instances can be used as arguments in {Page#evaluate_function},
  # {Page#query_selector_evaluate} and {Page#evaluate_function_handle} methods.
  #
  class JSHandle
    include Promise::Await
    # @!visibility private
    #
    attr_reader :context, :client, :remote_object

    # @!visibility private
    #
    def self.create_js_handle(context, remote_object)
      frame = context.frame

      if remote_object["subtype"] == 'node' && frame
        frame_manager = frame.frame_manager
        return  ElementHandle.new context, context.client, remote_object, frame_manager.page, frame_manager
      end

      JSHandle.new context, context.client, remote_object
    end

    # @!visibility private
    #
    # @param context [Rammus::ExecutionContext]
    # @param client [Rammus::CDPSession] client
    # @param remote_object [Protocol.Runtime.RemoteObject]
    #
    def initialize(context, client, remote_object)
      @context = context
      @client = client
      @remote_object = remote_object
      @_disposed = false
    end

    # Execution context the handle belongs to
    #
    # @return [Rammus::ExecutionContext]
    #
    def execution_context
      @context
    end

    # If this JsHandle has been released in chrome
    #
    # @return [Boolean]
    #
    def disposed?
      @_disposed
    end

    # Fetches a single property from the referenced object.
    #
    # @param property_name [String] property to get
    #
    # @return [Rammus::JsHandle]
    #
    def get_property(property_name)
      function = <<~JAVASCRIPT
      (object, propertyName) => {
        const result = {__proto__: null};
        result[propertyName] = object[propertyName];
        return result;
      }
      JAVASCRIPT
      object_handle = await execution_context.evaluate_handle_function function, self, property_name
      properties = object_handle.get_properties
      result = properties[property_name]
      object_handle.dispose
      result
    end

    # Fetches properties of the remote object
    #
    # @return [Map<string, JSHandle>>]
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

    # Returns a JSON representation of the object. If the object has a toJSON
    # function, it will not be called.
    #
    # @note The method will return an empty JSON object if the referenced
    #   object is not stringifiable. It will throw an error if the object has
    #   circular references.
    #
    # @return [Hash]
    #
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

    # Returns either nil or the object handle itself, if the object handle is
    # an instance of {ElementHandle}.
    #
    # @return [Rammus::ElementHandle, nil]
    #
    def as_element
      nil
    end

    # Clear the handle to be garbage collected in chrome
    #
    # @return nil
    #
    def dispose
      return if @_disposed

      @_disposed = true
      Util.release_object client, remote_object if remote_object["objectId"]
      nil
    end

    # If this JSHandle is disposed
    #
    # @return [Boolean]
    #
    def disposed?
      @_disposed
    end

    # String representation of JsHandle
    #
    # @return [String]
    #
    def to_s
      if remote_object["objectId"]
        type = remote_object["subtype"] || remote_object["type"]
        return "JSHandle@#{type}"
      end
      "JSHandle:#{Util.value_from_remote_object remote_object}"
    end
  end
end
