require 'bundler'
Bundler.require :test
require 'qu'
require 'qu/backend/spec'

module ServiceHelpers
  def service_running?(service)
    case service.to_s
    when "dynamo_db", "sqs"
      host = AWS.config.send("#{service}_endpoint")
      port = AWS.config.send("#{service}_port")
      Net::HTTP.new(host, port).request(Net::HTTP::Get.new("/"))
      true
    when "mongo"
      uri = ENV['MONGOHQ_URL'] || ENV['MONGOLAB_URI'] || ENV['BOXEN_MONGODB_URL']

      client = if uri.empty?
        Mongo::MongoClient.new
      else
        Mongo::MongoClient.from_uri(uri)
      end

      client.ping
      true
    when "redis"
      url = ENV['REDISTOGO_URL'] || ENV['BOXEN_REDIS_URL']

      client = if url.empty?
        Redis.new
      else
        Redis.connect(:url => url)
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

RSpec.configure do |config|
  config.include ServiceHelpers
  config.extend ServiceHelpers

  config.before(:each) do
    Qu.backend = mock('a backend', :reserve => nil, :failed => nil, :completed => nil,
      :register_worker => nil, :unregister_worker => nil)
    Qu.failure = nil
  end
end

Qu.logger = Logger.new('/dev/null')
