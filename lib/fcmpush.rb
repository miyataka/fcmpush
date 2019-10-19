require 'net/http/persistent'
require 'googleauth'

require 'fcmpush/configuration'
require 'fcmpush/version'
require 'fcmpush/client'

module Fcmpush
  class Error < StandardError; end
  DOMAIN = 'https://fcm.googleapis.com'.freeze

  class << self
    def build(project_id, domain: nil)
      ::Fcmpush::Client.new(domain || DOMAIN, project_id, configuration)
    end
    alias new build
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure(&block)
    yield(configuration(&block))
  end
end
