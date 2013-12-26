require 'mongo'

module Qu
  module Backend
    class Mongo < Base

      # Number of times to retry connection on connection failure (default: 5)
      attr_accessor :max_retries

      # Seconds to wait before try to reconnect after connection failure (default: 1)
      attr_accessor :retry_frequency

      # Seconds to wait before looking for more jobs when the queue is empty (default: 5)
      attr_accessor :poll_frequency

      def initialize
        self.max_retries     = 5
        self.retry_frequency = 1
        self.poll_frequency  = 5
      end

      def connection
        @connection ||= begin
          host_uri = (ENV['MONGOHQ_URL'] || ENV['MONGOLAB_URI'] || ENV['BOXEN_MONGODB_URL']).to_s
          if host_uri && !host_uri.empty?
            uri = URI.parse(host_uri)

            # path can come in as nil, "", "/", or "/something";
            # this normalizes to empty string or "something"
            path = uri.path.to_s[1..-1].to_s
            database = path.empty? ? 'qu' : path
            uri.path = "/#{database}"
            ::Mongo::MongoClient.from_uri(host_uri).db(database)
          else
            ::Mongo::MongoClient.new.db('qu')
          end
        end
      end

      def clear(queue = 'default')
        rescue_connection_failure do
          jobs(queue).drop
        end
      end

      def length(queue = 'default')
        rescue_connection_failure do
          jobs(queue).count
        end
      end

      def push(payload)
        payload.id = id_for_payload(payload)
        rescue_connection_failure do
          jobs(payload.queue).insert(payload_attributes(payload))
        end
        payload
      end

      def pop(worker, options = {:block => true})
        loop do
          worker.queues.each do |queue|
            begin
              doc = rescue_connection_failure do
                jobs(queue).find_and_modify(:remove => true)
              end

              if doc
                doc['id'] = doc.delete('_id')
                return Payload.new(doc)
              end
            rescue ::Mongo::OperationFailure
              # No jobs in the queue (MongoDB <2)
            end
          end

          if options[:block]
            sleep poll_frequency
          else
            break
          end
        end
      end

      def release(payload)
        rescue_connection_failure do
          jobs(payload.queue).insert(payload_attributes(payload))
        end
      end

      def completed(payload)
      end

    protected
      def payload_attributes(payload)
        {:_id => payload.id, :klass => payload.klass.to_s, :args => payload.args}
      end

      def id_for_payload(payload)
        BSON::ObjectId.new
      end

      private

      def jobs(queue)
        connection["qu:queue:#{queue}"]
      end

      def rescue_connection_failure
        retries = 0
        begin
          yield
        rescue ::Mongo::ConnectionFailure => ex
          retries += 1
          raise ex if retries > max_retries
          sleep retry_frequency * retries
          retry
        end
      end
    end
  end
end
