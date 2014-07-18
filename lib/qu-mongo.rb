require 'qu'
require 'qu/queues/mongo'

Qu.queue = Qu::Queues::Mongo.new
