module Fcmpush
  module Batch
    PART_BOUNDRY = '__END_OF_PART__'.freeze

    def make_batch_payload(messages, headers)
      uri = URI.join(domain, path)
      subrequests = messages.map do |payload|
        req = Net::HTTP::Post.new(uri, headers)
        req.body = payload
        req
      end
      subrequests.map.with_index { |req, idx| create_part(req, PART_BOUNDRY, idx) }.join + "--#{PART_BOUNDRY}\r\n"
    end

    def create_part(request, part_boundry, idx)
      serialized_request = serialize_sub_request(request)
      "--#{part_boundry}\r\n" \
        "Content-Length: #{serialized_request.length}\r\n" \
        "Content-Type: application/http\r\n" \
        "Content-Id: #{idx + 1}\r\n" \
        "Content-Transfer-Encoding: binary\r\n" \
        "\r\n" \
        "#{serialized_request}\r\n"
    end

    def serialize_sub_request(request)
      body_str = request.body.is_a?(String) ? request.body : request.body.to_json
      subreqest = "POST #{request.path} HTTP/1.1\r\n" \
                  "Content-Length: #{body_str.length}\r\n"
      request.to_hash.each do |k, v|
        subreqest += "#{k}: #{v.join(';')}\r\n"
      end
      subreqest += "\r\n" \
                   "#{body_str}\r\n"
    end
  end
end
