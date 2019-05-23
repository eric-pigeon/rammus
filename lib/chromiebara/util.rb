module Chromiebara
  module Util
    # [Protocol.Runtime.RemoteObject] remote_object
    #
    def self.value_from_remote_object(remote_object)
      byebug if remote_object["objectId"]
      raise "Cannot extract value when objectId is given" if remote_object["objectId"]
      if remote_object["unserializableValue"]
        # if (remoteObject.type === 'bigint' && typeof BigInt !== 'undefined')
        #   return BigInt(remoteObject.unserializableValue.replace('n', ''));
        case remote_object["unserializableValue"]
        when '-0'
          raise 'TODO'
        when 'NaN'
          raise 'TODO'
        when 'Infinity'
          raise 'TODO'
        when '-Infinity'
          raise 'TODO'
        else
          raise "Unsupported unserializable value #{remote_object["unserializableValue"]}"
        end
      end
      return remote_object["value"]
    end
  end
end
