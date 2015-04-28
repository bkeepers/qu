require 'pp'
require 'pathname'
root_path = Pathname(__FILE__).dirname.join('..').expand_path
lib_path  = root_path.join('lib')
$:.unshift(lib_path)

require 'qu-redis'

queue = Qu::Queues::Redis.new
queue.connection.flushdb

Qu.register :default, queue

Qu.configure do |config|
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::DEBUG
end

def work_and_die(die_after_seconds = 1, *queues)
  queues = [:redis] if queues.empty?
  worker = Qu::Worker.new(queues)

  # tell qu worker to terminate after N seconds by sending terminate signal
  Thread.new {
    sleep die_after_seconds
    Process.kill 'SIGTERM', $$
  }

  begin
    worker.start
  rescue Qu::Worker::Stop
    puts 'worker stopped'
  rescue Qu::Worker::Abort
    puts 'worker aborted'
  end
end
