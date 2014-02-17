require 'mongo'

module Qu
  module Backend
    class Mongo < Base

      # Number of times to retry connection on connection failure (default: 5)
      attr_accessor :max_retries

      # Seconds to wait before try to reconnect after connection
      # failure (default: 1)
      attr_accessor :retry_frequency

      def initialize
        self.max_retries     = 5
        self.retry_frequency = 1
      end

      def push(payload)
        payload.id = BSON::ObjectId.new
        with_connection_retries do
          jobs(payload.queue).insert(payload_attributes(payload))
        end
        payload
      end

      def abort(payload)
        with_connection_retries do
          jobs(payload.queue).insert(payload_attributes(payload))
        end
      end

      def pop(queue = 'default')
        begin
          doc = with_connection_retries do
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

      def size(queue = 'default')
        with_connection_retries do
          jobs(queue).count
        end
      end

      def clear(queue = 'default')
        with_connection_retries do
          jobs(queue).drop
        end
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

      def reconnect
        connection.connection.reconnect
      end

      private

      def payload_attributes(payload)
        attrs = payload.attributes_for_push
        attrs[:_id] = attrs.delete(:id)
        attrs
      end

      def jobs(queue)
        connection["qu:queue:#{queue}"]
      end

      def with_connection_retries
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
