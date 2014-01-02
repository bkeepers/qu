require 'pp'
require 'pathname'
root_path = Pathname(__FILE__).dirname.join('..').expand_path
lib_path  = root_path.join('lib')
$:.unshift(lib_path)

require 'qu-redis'

backend = Qu::Backend::Redis.new
backend.connection.flushdb

Qu.configure do |config|
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::DEBUG
  config.graceful_shutdown = false
  config.backend = backend
end
