require 'redis-namespace'
require 'simple_uuid'

module Qu
  module Backend
    class Redis < Base
      attr_accessor :namespace

      def initialize
        self.namespace = :qu
      end

      def push(payload)
        payload.id = SimpleUUID::UUID.new.to_guid
        connection.set("job:#{payload.id}", encode('klass' => payload.klass.to_s, 'args' => payload.args))
        connection.rpush("queue:#{payload.queue}", payload.id)
        connection.sadd('queues', payload.queue)
        payload
      end

      def pop(worker)
        worker.queues.each do |queue_name|
          if id = connection.lpop("queue:#{queue_name}")
            if data = connection.get("job:#{id}")
              data = decode(data)
              return Payload.new(:id => id, :klass => data['klass'], :args => data['args'])
            end
          end
        end

        nil
      end

      def abort(payload)
        connection.rpush("queue:#{payload.queue}", payload.id)
      end

      def complete(payload)
        connection.del("job:#{payload.id}")
      end

      def size(queue = 'default')
        connection.llen("queue:#{queue}")
      end

      def clear(queue = 'default')
        while id = connection.lpop("queue:#{queue}")
          connection.del("job:#{id}")
        end
      end

      def connection
        @connection ||= ::Redis::Namespace.new(namespace, :redis => ::Redis.connect(:url => ENV['REDISTOGO_URL'] || ENV['BOXEN_REDIS_URL']))
      end
    end
  end
end
