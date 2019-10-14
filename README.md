# Fcmpush [![Build Status](https://travis-ci.org/miyataka/fcmpush.svg?branch=master)](https://travis-ci.org/miyataka/fcmpush)

Fcmpush is an Firebase Cloud Messaging(FCM) Client. It implements [FCM HTTP v1 API](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages).
This gem supports HTTP v1 API only, **NOT supported [legacy HTTP protocol](https://firebase.google.com/docs/cloud-messaging/http-server-ref)**, because both authentication method is different.

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
  # firebase web console => project settings => service account => firebase admin sdk => generate new private key
  config.json_key_io = "#{Rails.root}/path/to/service_account_credentials.json"

  # Or set environment variables
  # ENV['GOOGLE_ACCOUNT_TYPE'] = 'service_account'
  # ENV['GOOGLE_CLIENT_ID'] = '000000000000000000000'
  # ENV['GOOGLE_CLIENT_EMAIL'] = 'xxxx@xxxx.iam.gserviceaccount.com'
  # ENV['GOOGLE_PRIVATE_KEY'] = '-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n\
end
```

for more detail. see [here](https://github.com/googleapis/google-auth-library-ruby#example-service-account).

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

## Future Work
- topic subscribe/unsubscribe
- auto refresh access_token before expiry
- [DEV] compare other gems

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/miyataka/fcmpush.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
