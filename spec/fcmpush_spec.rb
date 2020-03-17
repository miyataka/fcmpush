RSpec.describe Fcmpush do
  let(:device_token) { ENV.fetch('TEST_DEVICE_TOKEN') }
  let(:project_id) { ENV.fetch('TEST_PROJECT_ID') }
  let(:server_key) { ENV.fetch('FCM_SERVER_KEY') }
  let(:json_key_path) { ENV.fetch('TEST_JSON_KEY_PATH') }
  let(:json_key_string) { JSON.generate({client_email: ENV['GOOGLE_CLIENT_EMAIL'], private_key: ENV['GOOGLE_PRIVATE_KEY']}) }

  it 'has a version number' do
    expect(Fcmpush::VERSION).not_to be nil
  end

  context 'Fcmpush::Client' do
    context '#push' do
      it 'simple smoke test' do
        client = Fcmpush.new(project_id)
        message_json = {
          message: {
            token: device_token,
            notification: {
              title: 'test title',
              body: 'test body'
            }
          }
        }
        response = client.push(message_json)

        json = response.json

        expect(response.code).to eq('200')
        expect(json[:name]).to start_with("projects/#{project_id}/messages/")
      end

      it 'token refresh test' do
        client = Fcmpush.new(project_id)
        message_json = {
          message: {
            token: device_token,
            notification: {
              title: 'test title',
              body: 'test body'
            }
          }
        }
        prev_token = client.access_token
        sleep 1 # because google auth returns cached response
        response = travel_to(Time.now.utc + 3600) { client.push(message_json) }
        refreshed_token = client.access_token

        json = response.json
        expect(response.code).to eq('200')
        expect(json[:name]).to start_with("projects/#{project_id}/messages/")
        expect(prev_token).not_to eq(refreshed_token)
      end
    end

    context '#subscribe' do
      it 'subscribe test' do
        client = Fcmpush.new(project_id)
        response = client.subscribe('/topics/test_topic', device_token)

        json = response.json

        expect(response.code).to eq('200')
        expect(json[:results]).to eq([{}])
      end
    end

    context '#unsubscribe' do
      it 'unsubscribe test' do
        client = Fcmpush.new(project_id)
        response = client.unsubscribe('/topics/test_topic', device_token)

        json = response.json

        expect(response.code).to eq('200')
        expect(json[:results]).to eq([{}])
      end
    end
  end

  context 'configuration compatibility check' do
    context 'json_key from file' do
      it 'smoke test' do
        Fcmpush.configure do |config|
          config.json_key_io = json_key_path
        end
        client = Fcmpush.new(project_id)
        message_json = {
          message: {
            token: device_token,
            notification: {
              title: 'test title',
              body: 'test body'
            }
          }
        }
        response = client.push(message_json)

        json = response.json

        expect(response.code).to eq('200')
        expect(json[:name]).to start_with("projects/#{project_id}/messages/")
      end
    end

    context 'json_key from IO' do
      require 'stringio'

      it 'smoke test' do
        Fcmpush.configure do |config|
          config.json_key_io = StringIO.new(json_key_string)
        end
        client = Fcmpush.new(project_id)
        message_json = {
          message: {
            token: device_token,
            notification: {
              title: 'test title',
              body: 'test body'
            }
          }
        }
        response = client.push(message_json)

        json = response.json

        expect(response.code).to eq('200')
        expect(json[:name]).to start_with("projects/#{project_id}/messages/")
      end
    end
  end
end
