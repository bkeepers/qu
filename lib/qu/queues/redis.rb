require 'redis-namespace'
require 'securerandom'

module Qu
  module Queues
    class Redis < Base
      def initialize(queue_name = :default, namespace = :qu)
        @queue_name = queue_name
        @namespace = namespace
      end

      def push(payload)
        payload.id = SecureRandom.uuid
        connection.rpush("queue:#{@queue_name}", dump(payload.attributes_for_push))
        payload
      end

      def abort(payload)
        connection.rpush("queue:#{@queue_name}", dump(payload.attributes_for_push))
      end

      def complete(payload)
      end

      def pop
        if data = connection.lpop("queue:#{@queue_name}")
          data = load(data)
          return Payload.new({
            id: data['id'],
            klass: data['klass'],
            args: data['args'],
          })
        end
      end

      def size
        connection.llen("queue:#{@queue_name}")
      end

      def clear
        connection.del("queue:#{@queue_name}")
      end

      def connection
        @connection ||= ::Redis::Namespace.new(@namespace, :redis => ::Redis.connect(:url => ENV['REDISTOGO_URL'] || ENV['BOXEN_REDIS_URL']))
      end

      def reconnect
        connection.client.reconnect
      end
    end
  end
end
