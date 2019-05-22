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

    # @param [Chromiebara::ExecutionContext] context
    # @param [Chromiebara::CDPSession] client
    # @param [Protocol.Runtime.RemoteObject] remote_object
    def initialize(context, client, remote_object)
      @context = context
      @client = client
      @remote_object = remote_object
      @_disposed = false
    end

    # /**
    #  * @return {!Puppeteer.ExecutionContext}
    #  */
    # executionContext() {
    #   return this._context;
    # }

    # /**
    #  * @param {string} propertyName
    #  * @return {!Promise<?JSHandle>}
    #  */
    # async getProperty(propertyName) {
    #   const objectHandle = await this._context.evaluateHandle((object, propertyName) => {
    #     const result = {__proto__: null};
    #     result[propertyName] = object[propertyName];
    #     return result;
    #   }, this, propertyName);
    #   const properties = await objectHandle.getProperties();
    #   const result = properties.get(propertyName) || null;
    #   await objectHandle.dispose();
    #   return result;
    # }

    # /**
    #  * @return {!Promise<!Map<string, !JSHandle>>}
    #  */
    # async getProperties() {
    #   const response = await this._client.send('Runtime.getProperties', {
    #     objectId: this._remoteObject.objectId,
    #     ownProperties: true
    #   });
    #   const result = new Map();
    #   for (const property of response.result) {
    #     if (!property.enumerable)
    #       continue;
    #     result.set(property.name, createJSHandle(this._context, property.value));
    #   }
    #   return result;
    # }

    def json_value
      if remote_object["objectId"]
        response = await client.command Protocol::Runtime.call_function_on(
          function_declaration: 'function() { return this; }',
          object_id: remote_object["objectId"],
          return_by_value: true,
          await_promise: true
        )
        value_from_remote_object response["result"]
      end

      value_from_remote_object remote_object
    end

    # /**
    #  * @return {?Puppeteer.ElementHandle}
    #  */
    # asElement() {
    #   return null;
    # }

    def dispose
      return if @_disposed

      @_disposed = true
      if remote_object["objectId"]
        await client.command(Protocol::Runtime.release_object object_id: remote_object["objectId"]).catch do |error|
          # Exceptions might happen in case of a page been navigated or closed.
          # Swallow these since they are harmless and we don't leak anything in this case.
          # TODO
          raise error
        end
      end
    end

    # /**
    #  * @override
    #  * @return {string}
    #  */
    # toString() {
    #   if (this._remoteObject.objectId) {
    #     const type =  this._remoteObject.subtype || this._remoteObject.type;
    #     return 'JSHandle@' + type;
    #   }
    #   return 'JSHandle:' + helper.valueFromRemoteObject(this._remoteObject);
    # }

    private

      # [Protocol.Runtime.RemoteObject] remote_object
      #
      def value_from_remote_object(remote_object)
        raise "Cannot extract value when objectId is given" if remote_object["objectId"]
        if remote_object["unserializableValue"]
          raise 'TODO'
        # if (remoteObject.unserializableValue) {
        #   if (remoteObject.type === 'bigint' && typeof BigInt !== 'undefined')
        #     return BigInt(remoteObject.unserializableValue.replace('n', ''));
        #   switch (remoteObject.unserializableValue) {
        #     case '-0':
        #       return -0;
        #     case 'NaN':
        #       return NaN;
        #     case 'Infinity':
        #       return Infinity;
        #     case '-Infinity':
        #       return -Infinity;
        #     default:
        #       throw new Error('Unsupported unserializable value: ' + remoteObject.unserializableValue);
        #   }
        end
        return remote_object["value"];
      end
  end
end
