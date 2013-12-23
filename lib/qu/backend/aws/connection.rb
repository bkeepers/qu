require 'qu/backend/aws/sns/publisher'
require 'qu/backend/aws/sqs/publisher'
require 'qu/backend/aws/sqs/subscriber'
require 'qu/backend/aws/dynamo/state'

module Qu
  module Backend
    class AWS
      class Connection
        # Private
        attr_reader :publisher

        # Private
        attr_reader :subscriber

        # Private
        attr_reader :worker_state

        # Private
        attr_reader :queue_state

        def initialize(options = {})
          @publisher = options.fetch(:publisher) { AWS::SQS::Publisher.new }
          @subscriber = options.fetch(:subscriber) { AWS::SQS::Subscriber.new }
          @worker_state = options.fetch(:worker_state) { Dynamo::State.new("workers") }
          @queue_state = options.fetch(:queue_state) { Dynamo::State.new("queues") }
        end

        def enqueue(queue_name, body)
          publisher.publish(queue_name, body)
        end

        def dequeue(queue_name)
          subscriber.receive(queue_name)
        end

        def depth(queue_name)
          subscriber.depth(queue_name)
        end

        def drain(queue_name)
          subscriber.drain(queue_name)
        end

        def queues
          queue_state.map { |doc| doc[:id] }
        end

        def register_queue(queue_name)
          queue_state.register(queue_name)
        end

        def unregister_queue(queue_name)
          queue_state.unregister(queue_name)
        end

        def workers
          worker_state.map { |doc|
            hostname, pid, queues = doc[:id].split(':', 3)

            Qu::Worker.new({
              "hostname" => hostname,
              "pid" => pid.to_i,
              "queues" => queues.split(','),
            })
          }
        end

        def register_worker(worker)
          worker_state.register(worker.id)
        end

        def unregister_worker(worker)
          worker_state.unregister(worker.id)
        end

        def clear_workers(workers)
          worker_state.unregister(workers.map(&:id))
        end
      end
    end
  end
end
