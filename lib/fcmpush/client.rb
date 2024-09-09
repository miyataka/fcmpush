require 'fcmpush/exceptions'
require 'fcmpush/batch'
require 'fcmpush/json_response'
require 'fcmpush/batch_response'

module Fcmpush
  V1_ENDPOINT_PREFIX = '/v1/projects/'.freeze
  V1_ENDPOINT_SUFFIX = '/messages:send'.freeze
  TOPIC_DOMAIN = 'https://iid.googleapis.com'.freeze
  TOPIC_ENDPOINT_PREFIX = '/iid/v1'.freeze
  BATCH_ENDPOINT = '/batch'.freeze

  class Client
    include Batch
    attr_reader :domain, :path, :connection, :configuration, :server_key, :access_token, :access_token_expiry

    def initialize(domain, project_id, configuration, **options)
      @domain = domain
      @project_id = project_id
      @path = V1_ENDPOINT_PREFIX + project_id.to_s + V1_ENDPOINT_SUFFIX
      @options = {}.merge(options)
      @configuration = configuration.dup
      access_token_response = v1_authorize
      @access_token = access_token_response['access_token']
      @access_token_expiry = Time.now.utc + access_token_response['expires_in']
      # @server_key = configuration.server_key
      @connection = Net::HTTP::Persistent.new

      @connection.open_timeout = configuration.open_timeout if configuration.open_timeout
      @connection.read_timeout = configuration.read_timeout if configuration.read_timeout

      if !configuration.proxy
        # do nothing
      elsif configuration.proxy == :ENV
        @connection.proxy = :ENV
      elsif configuration.proxy && configuration.proxy[:uri]
        uri = URI(configuration.proxy[:uri])
        # user name must not be a empty string, password can
        if configuration.proxy[:user] && configuration.proxy[:user].strip != ''
          uri.user = configuration.proxy[:user]
          uri.password = configuration.proxy[:password] if configuration.proxy[:password]
        end
        @connection.proxy = uri
      end
    end

    def v1_authorize
      @auth ||= if configuration.json_key_io
                  io = if configuration.json_key_io.respond_to?(:read)
                         configuration.json_key_io
                       else
                         File.open(configuration.json_key_io)
                       end
                  io.rewind if io.respond_to?(:read)
                  Google::Auth::ServiceAccountCredentials.make_creds(
                    json_key_io: io,
                    scope: configuration.scope
                  )
                else
                  # from ENV
                  Google::Auth::ServiceAccountCredentials.make_creds(scope: configuration.scope)
                end
      @auth.fetch_access_token
    end

    def push(body, query: {}, headers: {})
      uri, request = make_push_request(body, query, headers)
      response = exception_handler(connection.request(uri, request))
      JsonResponse.new(response)
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
      raise NetworkError, "A network error occurred: #{e.class} (#{e.message})"
    end

    def subscribe(topic, *instance_ids, query: {}, headers: {})
      uri, request = make_subscription_request(topic, *instance_ids, :subscribe, query, headers)
      response = exception_handler(connection.request(uri, request))
      JsonResponse.new(response)
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
      raise NetworkError, "A network error occurred: #{e.class} (#{e.message})"
    end

    def unsubscribe(topic, *instance_ids, query: {}, headers: {})
      uri, request = make_subscription_request(topic, *instance_ids, :unsubscribe, query, headers)
      response = exception_handler(connection.request(uri, request))
      JsonResponse.new(response)
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
      raise NetworkError, "A network error occurred: #{e.class} (#{e.message})"
    end

    def batch_push(messages, query: {}, headers: {})
      uri, request = make_batch_request(messages, query, headers)
      response = exception_handler(connection.request(uri, request))
      BatchResponse.new(response)
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
      raise NetworkError, "A network error occurred: #{e.class} (#{e.message})"
    end

    private

      def make_push_request(body, query, headers)
        uri = URI.join(domain, path)
        uri.query = URI.encode_www_form(query) unless query.empty?

        access_token_refresh
        headers = v1_authorized_header(headers)
        post = Net::HTTP::Post.new(uri, headers)
        post.body = body.is_a?(String) ? body : body.to_json

        [uri, post]
      end

      def make_subscription_request(topic, instance_ids, type, query, headers)
        suffix = type == :subscribe ? ':batchAdd' : ':batchRemove'

        uri = URI.join(TOPIC_DOMAIN, TOPIC_ENDPOINT_PREFIX + suffix)
        uri.query = URI.encode_www_form(query) unless query.empty?

        headers = v1_authorized_header(headers)
        # cf. https://takanamito.hateblo.jp/entry/2020/07/04/175045
        # cf. https://github.com/miyataka/fcmpush/issues/40
        headers['access_token_auth'] = 'true'
        post = Net::HTTP::Post.new(uri, headers)
        post.body = make_subscription_body(topic, *instance_ids)

        [uri, post]
      end

      def access_token_refresh
        return if access_token_expiry > Time.now.utc + 300

        access_token_response = v1_authorize
        @access_token = access_token_response['access_token']
        @access_token_expiry = Time.now.utc + access_token_response['expires_in']
      end

      def v1_authorized_header(headers)
        headers.merge('Content-Type' => 'application/json',
                      'Accept' => 'application/json',
                      'Authorization' => "Bearer #{access_token}")
      end

      # @deprecated TODO: remove this method next version
      def legacy_authorized_header(headers)
        warn "[DEPRECATION] `legacy_authorized_header` is deprecated.  Please use `v1_authorized_header` instead."
        headers.merge('Content-Type' => 'application/json',
                      'Accept' => 'application/json',
                      'Authorization' => "Bearer #{server_key}")
      end

      def exception_handler(response)
        error = STATUS_TO_EXCEPTION_MAPPING[response.code]
        raise error.new("Received an error response #{response.code} #{error.to_s.split('::').last}: #{response.body}", response) if error

        response
      rescue Exception => e
        response
      end

      def make_subscription_body(topic, *instance_ids)
        topic = topic.match(%r{^/topics/}) ? topic : '/topics/' + topic
        {
          to: topic,
          registration_tokens: instance_ids
        }.to_json
      end

      def make_batch_request(messages, query, headers)
        uri = URI.join(domain, BATCH_ENDPOINT)
        uri.query = URI.encode_www_form(query) unless query.empty?

        access_token_refresh
        headers = v1_authorized_header(headers)
        post = Net::HTTP::Post.new(uri, headers)
        post['Content-Type'] = "multipart/mixed; boundary=#{::Fcmpush::Batch::PART_BOUNDRY}"
        post.body = make_batch_payload(messages, headers)

        [uri, post]
      end
  end
end
