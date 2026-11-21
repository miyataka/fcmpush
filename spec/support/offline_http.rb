require 'webmock/rspec'
require 'openssl'
require 'tmpdir'
require 'json'

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.before(:suite) do
    @credentials_dir = Dir.mktmpdir('fcmpush-spec-')
    key = OpenSSL::PKey::RSA.new(2048)
    ENV['TEST_PROJECT_ID'] = 'offline-test-project'
    ENV['TEST_DEVICE_TOKEN'] = 'offline-device-token'
    ENV['FCM_SERVER_KEY'] = 'offline-server-key'
    ENV['GOOGLE_ACCOUNT_TYPE'] = 'service_account'
    ENV['GOOGLE_CLIENT_ID'] = '123456789'
    ENV['GOOGLE_CLIENT_EMAIL'] = 'test@offline-test-project.iam.gserviceaccount.com'
    ENV['GOOGLE_PRIVATE_KEY'] = key.to_pem
    credentials = {
      type: 'service_account', project_id: ENV['TEST_PROJECT_ID'],
      client_id: ENV['GOOGLE_CLIENT_ID'], client_email: ENV['GOOGLE_CLIENT_EMAIL'],
      private_key: key.to_pem, token_uri: 'https://oauth2.googleapis.com/token'
    }
    %w[TEST_JSON_KEY_PATH ANOTHER_TEST_JSON_KEY_PATH].each do |name|
      path = File.join(@credentials_dir, "#{name}.json")
      File.write(path, credentials.to_json)
      ENV[name] = path
    end
  end

  config.after(:suite) do
    FileUtils.remove_entry(@credentials_dir) if @credentials_dir
  end

  config.before do
    Fcmpush.reset
    token_number = 0
    stub_request(:post, %r{\Ahttps://(?:oauth2.googleapis.com/token|www.googleapis.com/oauth2/v4/token)\z}).to_return do
      token_number += 1
      { status: 200, headers: { 'Content-Type' => 'application/json' },
        body: { access_token: "offline-token-#{token_number}", expires_in: 3600, token_type: 'Bearer' }.to_json }
    end
    stub_request(:post, "https://fcm.googleapis.com/v1/projects/#{ENV['TEST_PROJECT_ID']}/messages:send")
      .with(headers: { 'Authorization' => /Bearer offline-token-/ }) do |request|
        JSON.parse(request.body).fetch('message').fetch('token') == ENV['TEST_DEVICE_TOKEN']
      end.to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                    body: { name: "projects/#{ENV['TEST_PROJECT_ID']}/messages/offline-message" }.to_json)
    %w[batchAdd batchRemove].each do |operation|
      stub_request(:post, "https://iid.googleapis.com/iid/v1:#{operation}")
        .with(headers: { 'Authorization' => /Bearer offline-token-/, 'access_token_auth' => 'true' }) do |request|
          payload = JSON.parse(request.body)
          payload['to'] == '/topics/test_topic' && payload['registration_tokens'] == [ENV['TEST_DEVICE_TOKEN']]
        end.to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: { results: [{}] }.to_json)
    end
  end
end
