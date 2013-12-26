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
        @connection ||= ::Redis::Namespace.new(namespace, :redis => ::Redis.connect(:url => ENV['REDISTOGO_URL'] || ENV['BOXEN_REDIS_URL']))
      end

      def enqueue(payload)
        payload.id = SimpleUUID::UUID.new.to_guid
        connection.set("job:#{payload.id}", encode('klass' => payload.klass.to_s, 'args' => payload.args))
        connection.rpush("queue:#{payload.queue}", payload.id)
        connection.sadd('queues', payload.queue)
        payload
      end

      def length(queue = 'default')
        connection.llen("queue:#{queue}")
      end

      def clear(queue = 'default')
        while id = connection.lpop("queue:#{queue}")
          connection.del("job:#{id}")
        end
      end

      def reserve(worker, options = {:block => true})
        queues = worker.queues.map {|q| "queue:#{q}" }

        if options[:block]
          id = connection.blpop(*queues.push(0))[1]
        else
          queues.detect {|queue| id = connection.lpop(queue) }
        end

        get(id) if id
      end

      def release(payload)
        connection.rpush("queue:#{payload.queue}", payload.id)
      end

      def completed(payload)
        connection.del("job:#{payload.id}")
      end

      private

      def get(id)
        if data = connection.get("job:#{id}")
          data = decode(data)
          Payload.new(:id => id, :klass => data['klass'], :args => data['args'])
        end
      end
    end
  end
end
