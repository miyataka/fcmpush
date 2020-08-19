RSpec.describe Fcmpush do
  let(:device_token) { ENV.fetch('TEST_DEVICE_TOKEN') }
  let(:project_id) { ENV.fetch('TEST_PROJECT_ID') }
  let(:server_key) { ENV.fetch('FCM_SERVER_KEY') }
  let(:json_key_path) { ENV.fetch('TEST_JSON_KEY_PATH') }
  let(:another_json_key_path) { ENV.fetch('ANOTHER_TEST_JSON_KEY_PATH') }

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

    context '#batch_push' do
      it 'batch test' do
        client = Fcmpush.new(project_id)
        message_jsons = 5.times.map do |i|
          { message: { token: device_token,
                       notification: { title: "test title#{i}",
                                       body: "test body#{i}" } } }
        end
        response = client.batch_push(message_jsons)

        json = response.json

        expect(response.code).to eq('200')
        expect(response.success_count).to eq(5)
        expect(response.failure_count).to eq(0)
        expect(json.length).to eq(5)
        result = json.all? { |i| i[:name]&.start_with?("projects/#{project_id}/messages/") }
        expect(result).to be true
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
          config.json_key_io = StringIO.new(File.read(json_key_path))
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

    context 'configuration is isolate between clients' do
      it 'smoke test' do
        unless ENV['ON_TRAVIS']
          Fcmpush.configure do |config|
            config.json_key_io = json_key_path
          end
          client_a = Fcmpush.new(project_id)

          Fcmpush.configure do |config|
            config.json_key_io = another_json_key_path
          end
          client_b = Fcmpush.new(project_id)
          expect(client_a.configuration.object_id).not_to eq(client_b.configuration.object_id)
        end
      end
    end
  end
end
