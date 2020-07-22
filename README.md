# Fcmpush [![Build Status](https://travis-ci.org/miyataka/fcmpush.svg?branch=master)](https://travis-ci.org/miyataka/fcmpush) [![Gem Version](https://badge.fury.io/rb/fcmpush.svg)](https://badge.fury.io/rb/fcmpush)

Fcmpush is an Firebase Cloud Messaging(FCM) Client. It implements [FCM HTTP v1 API](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages), including **Auto Refresh** access_token feature, and batch request!!
This gem supports HTTP v1 API only, **NOT supported [legacy HTTP protocol](https://firebase.google.com/docs/cloud-messaging/http-server-ref)**.

fcmpush is highly inspired by [andpush gem](https://github.com/yuki24/andpush).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fcmpush'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fcmpush

## Usage

on Rails, config/initializers/fcmpush.rb
```ruby
Fcmpush.configure do |config|
  ## for message push
  # firebase web console => project settings => service account => firebase admin sdk => generate new private key

  # pass string of path to credential file to config.json_key_io
  config.json_key_io = "#{Rails.root}/path/to/service_account_credentials.json"
  # Or content of json key file wrapped with StringIO
  # config.json_key_io = StringIO.new('{ ... }')

  # Or set environment variables
  # ENV['GOOGLE_ACCOUNT_TYPE'] = 'service_account'
  # ENV['GOOGLE_CLIENT_ID'] = '000000000000000000000'
  # ENV['GOOGLE_CLIENT_EMAIL'] = 'xxxx@xxxx.iam.gserviceaccount.com'
  # ENV['GOOGLE_PRIVATE_KEY'] = '-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n\'

  ## for topic subscribe/unsubscribe because they use regacy auth
  # firebase web console => project settings => cloud messaging => Project credentials => Server key
  config.server_key = 'your firebase server key'
  # Or set environment variables
  # ENV['FCM_SERVER_KEY'] = 'your firebase server key'
end
```

for more detail. see [here](https://github.com/googleapis/google-auth-library-ruby#example-service-account).

### push message
```ruby
require 'fcmpush'

project_id   = "..." # Your project_id
device_token = "..." # The device token of the device you'd like to push a message to

client  = Fcmpush.new(project_id)
payload = { # ref. https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages
  message: {
    token: device_token,
    notification: {
      title: "this is title",
      body: "this is message body"
    }
  }
}

response = client.push(payload)

json = response.json
json[:name] # => "projects/[your_project_id]/messages/0:1571037134532751%31bd1c9631bd1c96"
```

### push messages in batch
```ruby
require 'fcmpush'

project_id   = "..." # Your project_id
device_tokens = ["...A", "...B", "...C"] # The device token of the device you'd like to push a message to

client  = Fcmpush.new(project_id)

payloads = device_tokens.map do |token|
{ # ref. https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages
  message: {
    token: token,
    notification: {
      title: "this is title",
      body: "this is message body"
    }
  }
}
end

response = client.batch_push(payloads)

response_array = response.json
response_array.first[:name] # => "projects/[your_project_id]/messages/0:1571037134532751%31bd1c9631bd1c96"
```

### topic subscribe/unsubscribe
```ruby
require 'fcmpush'

project_id   = "..." # Your project_id
topic = "your_topic_name"
device_tokens = ["device_tokenA", "device_tokenB", ...] # The device tokens of the device you'd like to subscribe

client  = Fcmpush.new(project_id)

response = client.subscribe(topic, device_tokens)
# response = client.unsubscribe(topic, device_tokens)

json = response.json
json[:results] # => [{}, {"error":"NOT_FOUND"}, ...]  ref. https://developers.google.com/instance-id/reference/server#example_result_3
```

## Performance
- fcmpush's performance is good. (at least not so bad.)
- [andpush](https://github.com/yuki24/andpush) is the fastest, but it uses legacy HTTP API.
- fcmpush is fastest in gems using V1 HTTP API(fcmpush, [google-api-fcm](https://github.com/oniksfly/google-api-fcm), [firebase_cloud_messenger](https://github.com/vincedevendra/firebase_cloud_messenger)).
- benchmark detail is [here](https://gist.github.com/miyataka/8787021724ee7dc5cecea88913f3af8c).
```
Warming up --------------------------------------
             andpush     1.000  i/100ms
                 fcm     1.000  i/100ms
             fcmpush     1.000  i/100ms
      google-api-fcm     1.000  i/100ms
firebase_cloud_messenger
                         1.000  i/100ms
Calculating -------------------------------------
             andpush     13.161  (±15.2%) i/s -     63.000  in   5.010981s
                 fcm      6.177  (±16.2%) i/s -     30.000  in   5.066638s
             fcmpush      7.237  (±13.8%) i/s -     36.000  in   5.098668s
      google-api-fcm      6.889  (±14.5%) i/s -     33.000  in   5.031508s
firebase_cloud_messenger
                          2.766  (± 0.0%) i/s -     14.000  in   5.079574s

Comparison:
             andpush:       13.2 i/s
             fcmpush:        7.2 i/s - 1.82x  slower
      google-api-fcm:        6.9 i/s - 1.91x  slower
                 fcm:        6.2 i/s - 2.13x  slower
firebase_cloud_messenger:        2.8 i/s - 4.76x  slower
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/miyataka/fcmpush.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
