require 'redis-namespace'
require 'simple_uuid'

module Qu
  module Backend
    class Redis < Base
      attr_accessor :namespace

      def initialize
        self.namespace = :qu
      end

      def connection
        @connection ||= ::Redis::Namespace.new(namespace, :redis => ::Redis.connect(:url => ENV['REDISTOGO_URL']))
      end
      alias_method :redis, :connection

      def enqueue(klass, *args)
        job = Job.new(SimpleUUID::UUID.new.to_guid, klass, args)
        redis.set("job:#{job.id}", encode('class' => job.klass.to_s, 'args' => job.args))
        redis.rpush("queue:#{job.queue}", job.id)
        redis.sadd('queues', job.queue)
        job
      end

      def length(queue = 'default')
        redis.llen("queue:#{queue}")
      end

      def clear(queue = nil)
        queue ||= queues + ['failed']
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

        get(id) if id
      end

      def release(job)
        redis.rpush("queue:#{job.queue}", job.id)
      end

      def failed(job, error)
        redis.rpush("queue:failed", job.id)
      end

      def completed(job)
        redis.del("job:#{job.id}")
      end

      def requeue(id)
        if job = get(id)
          redis.lrem('queue:failed', 1, id)
          redis.rpush("queue:#{job.queue}", id)
          job
        else
          false
        end
      end

      def register_worker(worker)
        redis.set("worker:#{worker.id}", encode(worker.attributes))
        redis.sadd(:workers, worker.id)
      end

      def unregister_worker(id)
        redis.del("worker:#{id}")
        redis.srem('workers', id)
      end

      def workers
        Array(redis.smembers(:workers)).map { |id| worker(id) }.compact
      end

      def clear_workers
        while id = redis.spop(:workers)
          redis.del("worker:#{id}")
        end
      end

    private

      def worker(id)
        Qu::Worker.new(decode(redis.get("worker:#{id}")))
      end

      def get(id)
        if data = redis.get("job:#{id}")
          data = decode(data)
          Job.new(id, data['class'], data['args'])
        end
      end

    end
  end
end
