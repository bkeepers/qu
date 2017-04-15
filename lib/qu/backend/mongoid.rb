require 'mongoid'

module Qu
  module Backend
    class Mongoid < Base

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
          unless ::Mongoid.sessions[:default]
            if (uri = (ENV['MONGOHQ_URL'] || ENV['MONGOLAB_URI']).to_s) && !uri.empty?
              ::Mongoid.sessions = {:default => {:uri => uri, :max_retries_on_connection_failure => 4}}
            else
              ::Mongoid.connect_to('qu')
            end
          end
          ::Mongoid::Sessions.default
        end
      end
      alias_method :database, :connection

      def clear(queue = nil)
        queue ||= queues + ['failed']
        logger.info { "Clearing queues: #{queue.inspect}" }
        Array(queue).each do |q|
          logger.debug "Clearing queue #{q}"
          jobs(q).drop
          self[:queues].where({:name => q}).remove
        end
      end

      def queues
        self[:queues].find.map {|doc| doc['name'] }
      end

      def length(queue = 'default')
        jobs(queue).find.count
      end

      def enqueue(payload)
        payload.id = ::Moped::BSON::ObjectId.new
        jobs(payload.queue).insert({:_id => payload.id, :klass => payload.klass.to_s, :args => payload.args})
        self[:queues].where({:name => payload.queue}).upsert({:name => payload.queue})
        logger.debug { "Enqueued job #{payload}" }
        payload
      end

      def reserve(worker, options = {:block => true})
        loop do
          worker.queues.each do |queue|
            logger.debug { "Reserving job in queue #{queue}" }

            begin
              doc = connection.command(:findAndModify => jobs(queue).name, :remove => true)
              if doc && doc['value']
                doc = doc['value']
                doc['id'] = doc.delete('_id')
                return Payload.new(doc)
              end
            rescue ::Moped::Errors::OperationFailure
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

      def register_worker(worker)
        logger.debug "Registering worker #{worker.id}"
        self[:workers].insert(worker.attributes.merge(:id => worker.id))
      end

      def unregister_worker(worker)
        logger.debug "Unregistering worker #{worker.id}"
        self[:workers].where(:id => worker.id).remove
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
        database["qu:#{name}"]
      end

    end
  end
end
