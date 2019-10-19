RSpec.describe Fcmpush do
  let(:device_token) { ENV.fetch('TEST_DEVICE_TOKEN') }
  let(:project_id) { ENV.fetch('TEST_PROJECT_ID') }
  let(:server_key) { ENV.fetch('FCM_SERVER_KEY') }

  it 'has a version number' do
    expect(Fcmpush::VERSION).not_to be nil
  end

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

  it 'subscribe test' do
    client = Fcmpush.new(project_id)
    response = client.subscribe('/topics/test_topic', device_token)

    json = response.json

    expect(response.code).to eq('200')
    expect(json[:results]).to eq([{}])
  end

  it 'unsubscribe test' do
    client = Fcmpush.new(project_id)
    response = client.unsubscribe('/topics/test_topic', device_token)

    json = response.json

    expect(response.code).to eq('200')
    expect(json[:results]).to eq([{}])
  end
end
