require 'qu'
require 'qu/queues/redis'

Qu.queue = Qu::Queues::Redis.new