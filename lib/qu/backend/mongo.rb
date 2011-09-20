require 'mongo'

module Qu
  module Backend
    class Mongo < Base
      def database
        @database ||= ::Mongo::Connection.new.db('qu')
      end

      def clear(queue = nil)
        queue ||= queues + ['failed']
        Array(queue).each do |q|
          jobs(q).drop
          self[:queues].remove({:name => q})
        end
      end

      def queues
        self[:queues].find.map {|doc| doc['name'] }
      end

      def length(queue)
        jobs(queue).count
      end

      def enqueue(klass, *args)
        job = Qu::Job.new(BSON::ObjectId.new, klass, args)
        jobs(job.queue).insert({:_id => job.id, :class => job.klass.to_s, :args => job.args})
        self[:queues].update({:name => job.queue}, {:name => job.queue}, :upsert => true)
        job
      end

      def reserve(worker, options = {:block => true})
        worker.queues.each do |queue|
          begin
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

      def failed(job, error)
        jobs('failed').insert(:_id => job.id, :class => job.klass.to_s, :args => job.args, :queue => job.queue)
      end

      def requeue(id)
        doc = jobs('failed').find_and_modify(:query => {:_id => id}, :remove => true)
        jobs(doc.delete('queue')).insert(doc)
        Job.new(doc['_id'], doc['class'], doc['args'])
      rescue ::Mongo::OperationFailure
        false
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