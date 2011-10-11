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
          uri = URI.parse(ENV['MONGOHQ_URL'].to_s)
          database = uri.path.empty? ? 'qu' : uri.path[1..-1]
          options = {}
          if uri.password
            options[:auths] = [{
              'db_name'  => database,
              'username' => uri.user,
              'password' => uri.password
            }]
          end
          ::Mongo::Connection.new(uri.host, uri.port, options).db(database)
        end
      end
      alias_method :database, :connection

      def clear(queue = nil)
        queue ||= queues + ['failed']
        logger.info { "Clearing queues: #{queue.inspect}" }
        Array(queue).each do |q|
          logger.debug "Clearing queue #{q}"
          jobs(q).drop
          self[:queues].remove({:name => q})
        end
      end

      def queues
        self[:queues].find.map {|doc| doc['name'] }
      end

      def length(queue = 'default')
        jobs(queue).count
      end

      def enqueue(payload)
        payload.id = BSON::ObjectId.new
        jobs(payload.queue).insert({:_id => payload.id, :klass => payload.klass.to_s, :args => payload.args})
        self[:queues].update({:name => payload.queue}, {:name => payload.queue}, :upsert => true)
        logger.debug { "Enqueued job #{payload}" }
        payload
      end

      def reserve(worker, options = {:block => true})
        loop do
          worker.queues.each do |queue|
            logger.debug { "Reserving job in queue #{queue}" }

            begin
              if doc = jobs(queue).find_and_modify(:remove => true)
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
        jobs(payload.queue).insert({:_id => payload.id, :klass => payload.klass.to_s, :args => payload.args})
      end

      def failed(payload, error)
        jobs('failed').insert(:_id => payload.id, :klass => payload.klass.to_s, :args => payload.args, :queue => payload.queue)
      end

      def completed(payload)
      end

      def requeue(id)
        logger.debug "Requeuing job #{id}"
        doc = jobs('failed').find_and_modify(:query => {:_id => id}, :remove => true) || raise(::Mongo::OperationFailure)
        jobs(doc.delete('queue')).insert(doc)
        doc['id'] = doc.delete('_id')
        Payload.new(doc)
      rescue ::Mongo::OperationFailure
        false
      end

      def register_worker(worker)
        logger.debug "Registering worker #{worker.id}"
        self[:workers].insert(worker.attributes.merge(:id => worker.id))
      end

      def unregister_worker(worker)
        logger.debug "Unregistering worker #{worker.id}"
        self[:workers].remove(:id => worker.id)
      end

      def workers
        self[:workers].find.map do |doc|
          Qu::Worker.new(doc)
        end
      end

      def clear_workers
        logger.info "Clearing workers"
        self[:workers].drop
      end

    private

      def jobs(queue)
        self["queue:#{queue}"]
      end

      def [](name)
        rescue_connection_failure do
          database["qu:#{name}"]
        end
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