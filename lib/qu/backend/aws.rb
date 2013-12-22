require 'digest/sha1'

module Qu
  module Backend
    class AWS < Base
      # Seconds to wait before looking for more jobs when the queue is empty (default: 5)
      attr_accessor :poll_frequency

      def initialize
        self.poll_frequency  = 5
      end

      def enqueue(payload)
        # id does not really matter for aws as they have ids already so i'm just
        # sending something relatively unique for errors and what not
        payload.id = Digest::SHA1.hexdigest(payload.to_s + Time.now.to_s)

        connection.enqueue(payload.queue, encode(payload.attributes))
        connection.register_queue(payload.queue)

        logger.debug { "Enqueued job #{payload}" }
        payload
      end

      def completed(payload)
        payload.message.delete
      end

      def release(payload)
        payload.message.delete
        connection.enqueue(payload.queue, encode(payload.attributes))
      end

      def failed(payload, error)
        attrs = payload.attributes.merge(:queue => payload.queue)
        connection.enqueue('failed', encode(attrs))
      end

      def reserve(worker, options = {:block => true})
        loop do
          worker.queues.each do |queue_name|
            logger.debug { "Reserving job in queue #{queue_name}" }

            if message = connection.dequeue(queue_name)
              doc = decode(message.body)
              payload = Payload.new(doc)
              payload.message = message
              return payload
            end
          end

          if options[:block]
            sleep poll_frequency
          else
            break
          end
        end
      end

      def length(queue_name = 'default')
        connection.depth(queue_name)
      end

      def clear(queue_name = nil)
        if queue_name.nil?
          (queues + ['failed']).each do |name|
            connection.drain(name)
            connection.unregister_queue(name)
          end
        else
          connection.drain(queue_name)
          connection.unregister_queue(queue_name)
        end
      end

      def queues
        connection.queues
      end

      def register_worker(worker)
        connection.register_worker(worker)
      end

      def unregister_worker(worker)
        connection.unregister_worker(worker)
      end

      def workers
        connection.workers
      end

      def clear_workers
        connection.clear_workers(workers)
      end

      def connection
        @connection ||= AWS::Connection.new
      end

      def connection=(new_connection)
        @connection = new_connection
      end
    end
  end
end

require 'qu/backend/aws/connection'
