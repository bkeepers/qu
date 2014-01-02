require 'bundler'
Bundler.require :test
require 'qu'
require 'qu/backend/spec'

root_path = Pathname(__FILE__).dirname.join('..').expand_path
Dir[root_path.join("spec/support/**/*.rb")].each { |f| require f }

module Qu
  module Specs
    def self.perform?(class_under_spec, *service_names)
      services = service_names.flatten
      return true if services.size == 0

      down_services = services.select { |service| !running?(service) }
      unless down_services.empty?
        puts "Skipping #{class_under_spec}. Required services are not running (#{down_services.join(', ')})."
      end
    end

    def self.running?(service)
      case service.to_s
      when "sqs"
        host = AWS.config.send("#{service}_endpoint")
        port = AWS.config.send("#{service}_port")
        Net::HTTP.new(host, port).request(Net::HTTP::Get.new("/"))
        true
      when "mongo"
        uri = ENV['MONGOHQ_URL'] || ENV['MONGOLAB_URI'] || ENV['BOXEN_MONGODB_URL']

        client = if uri.nil? || uri.empty?
          Mongo::MongoClient.new
        else
          Mongo::MongoClient.from_uri(uri)
        end

        client.ping
        true
      when "redis"
        uri = ENV['REDISTOGO_URL'] || ENV['BOXEN_REDIS_URL']

        client = if uri.nil? || uri.empty?
          Redis.new
        else
          Redis.connect(:url => uri)
        end

        client.ping
        true
      else
        false
      end
    rescue => exception
      false
    end
  end
end

RSpec.configure do |config|
  config.before(:each) do
    Qu.backend = double('a backend', {
      :push => nil,
      :pop => nil,
      :complete => nil,
      :abort => nil,
    })
  end
end

Qu.logger = Logger.new('/dev/null')
