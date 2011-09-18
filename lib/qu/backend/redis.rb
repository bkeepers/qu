require 'redis'

module Qu
  module Backend
    class Redis < Base
      def redis
        @redis ||= ::Redis.connect
      end

      def enqueue(klass, *args)
        data = encode('class' => klass.to_s, 'args' => args)
        id = unique_id(data)
        redis.set("job:#{id}", data)
        redis.rpush("queue:#{klass.queue}", id)
        redis.sadd('queues', klass.queue)
        id
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
          Job.load(id, data['class'], data['args'])
        end
      end

    private

      def unique_id(data)
        Digest::MD5.hexdigest("#{Time.now.to_f} - #{rand} - #{data}")
      end

    end
  end
end
