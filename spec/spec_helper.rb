require 'bundler'
Bundler.require :test
require 'qu'
require 'qu/queues/spec'
require 'qu/runner/spec'

root_path = Pathname(__FILE__).dirname.join('..').expand_path
Dir[root_path.join("spec/support/**/*.rb")].each { |f| require f }

module Qu
  module Specs
    def self.perform?(class_under_spec, *service_names)
      services = service_names.flatten
      return true if services.size == 0

      down_services = services.select { |service| !running?(service) }
      if down_services.any?
        puts "Skipping #{class_under_spec}. Required services are not running (#{down_services.join(', ')})."
      else
        true
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

log_path = root_path.join("log")
log_path.mkpath
log_file = log_path.join("qu.log")
log_to = ENV.fetch("QU_LOG_STDOUT", false) ? STDOUT : log_file

Qu.logger = Logger.new(log_to)
