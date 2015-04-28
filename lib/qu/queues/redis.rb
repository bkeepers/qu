require 'redis-namespace'
require 'securerandom'

module Qu
  module Queues
    class Redis < Base
      attr_accessor :namespace

      def initialize(name = "default")
        self.name = name
        self.namespace = :qu
      end

      def push(payload)
        payload.id = SecureRandom.uuid
        connection.rpush("queue:#{name}", dump(payload.attributes_for_push))
        payload
      end

      def abort(payload)
        connection.rpush("queue:#{name}", dump(payload.attributes_for_push))
      end

      def complete(payload)
      end

      def pop
        if data = connection.lpop("queue:#{name}")
          data = load(data)
          return Payload.new({
            id: data['id'],
            klass: data['klass'],
            args: data['args'],
          })
        end
      end

      def size
        connection.llen("queue:#{name}")
      end

      def clear
        connection.del("queue:#{name}")
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
