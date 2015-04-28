require 'qu'
require 'qu/queues/mongo'

Qu.register :mongo, Qu::Queues::Mongo.new
