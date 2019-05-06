module Chromiebara
  module Protocol
    module Audits
      extend self

      # Returns the response body and size if it were re-encoded with the specified settings. Only
      # applies to images.
      #
      # @param request_id [Network.requestid] Identifier of the network request to get content for.
      # @param encoding [String] The encoding to use.
      # @param quality [Number] The quality of the encoding (0-1). (defaults to 1)
      # @param size_only [Boolean] Whether to only return the size information (defaults to false).
      #
      def get_encoded_response(request_id:, encoding:, quality: nil, size_only: nil)
        {
          method: "Audits.getEncodedResponse",
          params: { requestId: request_id, encoding: encoding, quality: quality, sizeOnly: size_only }.compact
        }
      end
    end
  end
end
