require 'qu'
require 'qu/queues/redis'

Qu.register :redis, Qu::Queues::Redis.new
