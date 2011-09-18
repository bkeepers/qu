require 'mongo'

module Qu
  module Backend
    class Mongo < Base
      def database
        @database ||= ::Mongo::Connection.new.db('qu')
      end

      def clear(queue = queues)
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
        id = BSON::ObjectId.new
        jobs(klass.queue).insert({:_id => id, :class => klass.to_s, :args => args})
        self[:queues].update({:name => klass.queue}, {:name => klass.queue}, :upsert => true)
        id
      end

      def reserve(worker, options = {:block => true})
        worker.queues.each do |queue|
          begin
            doc = jobs(queue).find_and_modify(:remove => true)
            return Job.load(doc['_id'], doc['class'], doc['args'])
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

      end

      def delete(job)

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