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

      def enqueue(payload)
        payload.id = SimpleUUID::UUID.new.to_guid
        redis.set("job:#{payload.id}", encode('klass' => payload.klass.to_s, 'args' => payload.args))
        redis.rpush("queue:#{payload.queue}", payload.id)
        redis.sadd('queues', payload.queue)
        logger.debug { "Enqueued job #{payload}" }
        payload
      end

      def length(queue = 'default')
        redis.llen("queue:#{queue}")
      end

      def clear(queue = nil)
        queue ||= queues + ['failed']
        logger.info { "Clearing queues: #{queue.inspect}" }
        Array(queue).each do |q|
          logger.debug "Clearing queue #{q}"
          while id = redis.lpop("queue:#{q}")
            logger.debug "Clearing job #{id}"
            redis.del("job:#{id}")
          end
          redis.srem('queues', q)
        end
      end

      def queues
        Array(redis.smembers('queues'))
      end

      def reserve(worker, options = {:block => true})
        queues = worker.queues.map {|q| "queue:#{q}" }

        logger.debug { "Reserving job in queues #{queues.inspect}"}

        if options[:block]
          id = redis.blpop(*queues.push(0))[1]
        else
          queues.detect {|queue| id = redis.lpop(queue) }
        end

        get(id) if id
      end

      def release(payload)
        redis.rpush("queue:#{payload.queue}", payload.id)
      end

      def failed(payload, error)
        redis.rpush("queue:failed", payload.id)
      end

      def completed(payload)
        redis.del("job:#{payload.id}")
      end

      def register_worker(worker)
        logger.debug "Registering worker #{worker.id}"
        redis.set("worker:#{worker.id}", encode(worker.attributes))
        redis.sadd(:workers, worker.id)
      end

      def unregister_worker(worker)
        logger.debug "Unregistering worker #{worker.id}"
        redis.del("worker:#{worker.id}")
        redis.srem('workers', worker.id)
      end

      def workers
        Array(redis.smembers(:workers)).map { |id| worker(id) }.compact
      end

      def clear_workers
        logger.info "Clearing workers"
        while id = redis.spop(:workers)
          logger.debug "Clearing worker #{id}"
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
          Payload.new(:id => id, :klass => data['klass'], :args => data['args'])
        end
      end

    end
  end
end
