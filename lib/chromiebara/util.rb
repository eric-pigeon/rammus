module Chromiebara
  module Util
    # [Protocol.Runtime.RemoteObject] remote_object
    #
    def self.value_from_remote_object(remote_object)
      byebug if remote_object["objectId"]
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
      return remote_object["value"]
    end
  end
end
