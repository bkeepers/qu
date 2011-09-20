require 'redis'
require 'simple_uuid'

module Qu
  module Backend
    class Redis < Base
      def redis
        @redis ||= ::Redis.connect
      end

      def enqueue(klass, *args)
        job = Job.new(SimpleUUID::UUID.new.to_guid, klass, args)
        redis.set("job:#{job.id}", encode('class' => job.klass.to_s, 'args' => job.args))
        redis.rpush("queue:#{job.queue}", job.id)
        redis.sadd('queues', job.queue)
        job
      end

      def length(queue)
        redis.llen("queue:#{queue}")
      end

      def clear(queue = queues)
        Array(queue).each do |q|
          redis.srem('queues', q)
          redis.del("queue:#{q}")
        end
      end

      def queues
        Array(redis.smembers('queues'))
      end

      def reserve(worker, options = {:block => true})
        queues = worker.queues.map {|q| "queue:#{q}" }

        if options[:block]
          id = redis.blpop(*queues.push(0))[1]
        else
          queues.detect {|queue| id = redis.lpop(queue) }
        end

        if id
          data = decode(redis.get("job:#{id}"))
          redis.del("job:#{id}")
          Job.new(id, data['class'], data['args'])
        end
      end
    end
  end
end
