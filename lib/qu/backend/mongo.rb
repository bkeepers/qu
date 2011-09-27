require 'mongo'

module Qu
  module Backend
    class Mongo < Base
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

      def enqueue(klass, *args)
        job = Qu::Job.new(BSON::ObjectId.new, klass, args)
        jobs(job.queue).insert({:_id => job.id, :class => job.klass.to_s, :args => job.args})
        self[:queues].update({:name => job.queue}, {:name => job.queue}, :upsert => true)
        logger.debug { "Enqueued job #{job.id} for #{job.klass} with: #{job.args.inspect}" }
        job
      end

      def reserve(worker, options = {:block => true})
        worker.queues.each do |queue|
          begin
            logger.debug { "Reserving job in queue #{queue}" }

            doc = jobs(queue).find_and_modify(:remove => true)
            return Job.new(doc['_id'], doc['class'], doc['args'])
          rescue ::Mongo::OperationFailure
            # No jobs in the queue
          end
        end

        if options[:block]
          sleep 5
          retry
        end
      end

      def release(job)
        jobs(job.queue).insert({:_id => job.id, :class => job.klass.to_s, :args => job.args})
      end

      def failed(job, error)
        jobs('failed').insert(:_id => job.id, :class => job.klass.to_s, :args => job.args, :queue => job.queue)
      end

      def completed(job)
      end

      def requeue(id)
        logger.debug "Requeuing job #{id}"
        doc = jobs('failed').find_and_modify(:query => {:_id => id}, :remove => true)
        jobs(doc.delete('queue')).insert(doc)
        Job.new(doc['_id'], doc['class'], doc['args'])
      rescue ::Mongo::OperationFailure
        false
      end

      def register_worker(worker)
        logger.debug "Registering worker #{worker.id}"
        self[:workers].insert(worker.attributes.merge(:id => worker.id))
      end

      def unregister_worker(id)
        logger.debug "Unregistering worker #{id}"
        self[:workers].remove(:id => id)
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
        database["qu.#{name}"]
      end
    end
  end
end