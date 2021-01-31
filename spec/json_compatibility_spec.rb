RSpec.describe Fcmpush do
  let(:device_token) { ENV.fetch('TEST_DEVICE_TOKEN') }
  let(:project_id) { ENV.fetch('TEST_PROJECT_ID') }
  let(:server_key) { ENV.fetch('FCM_SERVER_KEY') }
  let(:json_key_path) { ENV.fetch('TEST_JSON_KEY_PATH') }
  let(:another_json_key_path) { ENV.fetch('ANOTHER_TEST_JSON_KEY_PATH') }

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
