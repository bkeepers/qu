require 'socket'
require_relative './example_setup'
require 'qu/instrumentation/statsd'

Thread.new do
  socket = UDPSocket.new
  socket.bind(nil, 6868)
  loop do
    puts socket.recvfrom(50)[0].chomp
  end
end

# Config that matters to a user using qu
# 1. setup instrumenter
# 2. set client for subscriber
Qu.configure do |config|
  config.instrumenter = ActiveSupport::Notifications
end
Qu::Instrumentation::StatsdSubscriber.client = Statsd.new('localhost', 6868)

class SimpleJob < Qu::Job
  queue :redis
end

SimpleJob.create
SimpleJob.create

work_and_die
