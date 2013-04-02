require 'sequel'

module Qu
  module Backend
    class Sequel < Base
      JOB_TABLE_NAME = :qu_jobs
      WORKER_TABLE_NAME = :qu_workers

      attr_accessor :database_url, :poll_frequency

      def initialize
        self.database_url = ENV['DATABASE_URL']
        self.poll_frequency = 5
      end

      def self.create_tables(database)
        database.create_table?(JOB_TABLE_NAME) do
          primary_key :id
          String :queue, :null => false
          String :klass, :null => false
          column :args, :text
          DateTime :locked_at
        end

        database.create_table?(WORKER_TABLE_NAME) do
          primary_key :id
          String :hostname, :null => false
          Integer :pid, :null => false
          String :queues
        end
      end

      def connection
        @connection ||= ::Sequel.connect(database_url)
      end
      alias_method :database, :connection

      def enqueue(payload)
        id = insert_job(payload)
        payload.id = id

        logger.debug { "Enqueued job #{payload}" }

        payload
      end

      def length(queue = 'default')
        unlocked_queue_selection(queue).count
      end

      def clear(queue = nil)
        queue ||= queues + ['failed']

        logger.info { "Clearing queues: #{queue.inspect}" }

        Array(queue).each do |q|
          logger.debug "Clearing queue #{q}"
          unlocked_queue_selection(q).delete
        end
      end

      def queues
        job_table.distinct(:queue).select_map(:queue) - ['failed']
      end

      def reserve(worker, options = { :block => true })
        queues = worker.queues

        loop do
          logger.debug { "Reserving job in queues #{queues.inspect}"}

          record = nil

          queues.find { |queue|
            database.transaction do
              if record = unlocked_queue_selection(queue).for_update.limit(1).first
                job_table.where(:id => record[:id]).update(:locked_at => Time.now.utc)
              end
            end
          }

          if record
            return Qu::Payload.new(:id => record[:id], :klass => record[:klass], :args => decode(record[:args]))
          end

          if options[:block]
            sleep poll_frequency
          else
            break
          end
        end
      end

      def release(payload)
        job_table.where(:id => payload.id).update(:locked_at => nil)
      end

      def failed(payload, error)
        job_table.where(:id => payload.id).update(:queue => 'failed', :locked_at => nil)
      end

      def completed(payload)
        job_table.where(:id => payload.id).delete
      end

      def register_worker(worker)
        logger.debug "Registering worker #{worker.id}"
        insert_worker(worker)
      end

      def unregister_worker(worker)
        logger.debug "Unregistering worker #{worker.id}"
        worker_selection(worker).delete
      end

      def workers
        worker_table.all.map { |record|
          Qu::Worker.new(hostname: record[:hostname], pid: record[:pid], queues: decode(record[:queues]))
        }
      end

      def clear_workers
        logger.info "Clearing workers"
        worker_table.delete
      end

      protected
      def job_table
        @job_table ||= database[JOB_TABLE_NAME]
      end

      def worker_table
        @worker_table ||= database[WORKER_TABLE_NAME]
      end

      def queue_selection(name)
        job_table.where(:queue => name.to_s)
      end

      def unlocked_queue_selection(queue)
        queue_selection(queue).where(:locked_at => nil)
      end

      def worker_selection(worker)
        worker_table.where(worker_attributes(worker))
      end

      def worker_attributes(worker)
        { :hostname => worker.hostname, :pid => worker.pid, :queues => encode(worker.queues) }
      end

      def insert_job(payload, queue = nil)
        queue ||= payload.queue.to_s
        job_table.insert(:queue => queue, :klass => payload.klass.name, :args => encode(payload.args))
      end

      def insert_worker(worker)
        worker_table.insert(worker_attributes(worker))
      end
    end
  end
end
