require 'redis-namespace'
require 'securerandom'

module Qu
  module Queues
    class Redis < Base
      attr_accessor :namespace

      def initialize
        self.namespace = :qu
      end

      def push(payload)
        payload.id = SecureRandom.uuid
        connection.rpush("queue:#{payload.queue}", dump(payload.attributes_for_push))
        payload
      end

      def abort(payload)
        connection.rpush("queue:#{payload.queue}", dump(payload.attributes_for_push))
      end

      def complete(payload)
      end

      def pop(queue = 'default')
        if data = connection.lpop("queue:#{queue}")
          data = load(data)
          return Payload.new({
            id: data['id'],
            klass: data['klass'],
            args: data['args'],
          })
        end
      end

      def size(queue = 'default')
        connection.llen("queue:#{queue}")
      end

      def clear(queue = 'default')
        connection.del("queue:#{queue}")
      end

      def connection
        @connection ||= ::Redis::Namespace.new(namespace, :redis => ::Redis.connect(:url => ENV['REDISTOGO_URL'] || ENV['BOXEN_REDIS_URL']))
      end

      def reconnect
        connection.client.reconnect
      end
    end
  end
end
