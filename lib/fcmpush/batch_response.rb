require 'delegate' if RUBY_VERSION >= '2.7'

module Fcmpush
  class BatchResponse < DelegateClass(Net::HTTPResponse)
    alias response __getobj__
    alias headers to_hash
    HAS_SYMBOL_GC = RUBY_VERSION > '2.2.0'

    def json
      parsable? ? @parsed ||= parse_body(body) : nil
    end

    def inspect
      "#<BatchResponse response: #{response.inspect}, json: #{json}>"
    end
    alias to_s inspect

    def parsable?
      !body.nil? && !body.empty?
    end

    def success_count
      @success_count ||= json.length - failure_count
    end

    def failure_count
      @failure_count ||= json.select { |i| i[:error] }.size
    end

    private

      def parse_body(raw_body)
        devider = raw_body.match(/(\r\n--batch_.*)\r\n/)[1]
        raw_body.split(devider)[1..-2].map do |response|
          JSON.parse(response.split("\r\n\r\n")[2], symbolize_names: HAS_SYMBOL_GC)
        end
      end
  end
end
