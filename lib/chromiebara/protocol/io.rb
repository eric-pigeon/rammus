module Chromiebara
  module Protocol
    module IO
      extend self

      # Close the stream, discard any temporary backing storage.
      #
      # @param handle [Streamhandle] Handle of the stream to close.
      #
      def close(handle:)
        {
          method: "IO.close",
          params: { handle: handle }.compact
        }
      end

      # Read a chunk of the stream
      #
      # @param handle [Streamhandle] Handle of the stream to read.
      # @param offset [Integer] Seek to the specified offset before reading (if not specificed, proceed with offset following the last read). Some types of streams may only support sequential reads.
      # @param size [Integer] Maximum number of bytes to read (left upon the agent discretion if not specified).
      #
      def read(handle:, offset: nil, size: nil)
        {
          method: "IO.read",
          params: { handle: handle, offset: offset, size: size }.compact
        }
      end

      # Return UUID of Blob object specified by a remote object id.
      #
      # @param object_id [Runtime.remoteobjectid] Object id of a Blob object wrapper.
      #
      def resolve_blob(object_id:)
        {
          method: "IO.resolveBlob",
          params: { objectId: object_id }.compact
        }
      end
    end
  end
end
