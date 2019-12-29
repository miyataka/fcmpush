require 'delegate' if RUBY_VERSION >= '2.7'
require 'json'

module Fcmpush
  class JsonResponse < DelegateClass(Net::HTTPResponse)
    alias response __getobj__
    alias headers to_hash
    HAS_SYMBOL_GC = RUBY_VERSION > '2.2.0'

    def json
      parsable? ? JSON.parse(body, symbolize_names: HAS_SYMBOL_GC) : nil
    end

    def inspect
      "#<JsonResponse response: #{response.inspect}, json: #{json}>"
    end
    alias to_s inspect

    def parsable?
      !body.nil? && !body.empty?
    end
  end
end
