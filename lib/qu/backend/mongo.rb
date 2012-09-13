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

      def connection= db
        super
        db.create_collection 'qu.profiling', :capped => true, :size => 128*1024*1024
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

      def set payload, data
        set, unset = {}, {}
        (data.keys & [:save, :status, :progress]).each do |k|
          if data[k]
            set[k] = data[k]
          else
            unset[k] = 1
          end
        end
        jobs(payload.queue).update({ :_id => payload.id }, '$set' => set, '$unset' => unset)
      end

      def progress payload, value
        set payload, progress: value.to_i
      end

      def save payload, state
        set payload, save: state
      end

      def status payload, value
        set payload, status: value
      end

      def clear(queue = 'default')
        logger.info { "Clearing queues: #{queue.inspect}" }
        Array(queue).each do |q|
          logger.debug "Clearing queue #{q}"
          jobs(q).remove state: 'enq'
          # self[:queues].remove({:name => q}) if length(q).zero?
        end
      end

      def queues
        self[:queues].find.map {|doc| doc['name'] }
      end

      def length(queue = 'default')
        jobs(queue).find(:state => { '$ne' => 'die' }).count
      end

      def enqueue(payload)
        payload.id = BSON::ObjectId.new
        jobs(payload.queue).insert(
          :_id => payload.id,
          :klass => payload.klass.to_s, :args => payload.args,
          :added_at => Time.now,
          :state => 'enq')
        self[:queues].update({:name => payload.queue}, {:name => payload.queue}, :upsert => true)
        logger.debug { "Enqueued job #{payload}" }
        payload
      end

      def reserve(worker, options = {:block => true})
        loop do
          worker.queues.each do |queue|
            logger.debug { "Reserving job in queue #{queue}" }
            c = jobs queue
            c.ensure_index [['state', ::Mongo::ASCENDING]]

            begin
              doc = c.find_and_modify(
                :new => true,
                :query => { :state => 'enq' },
                :sort => { :added_at => 1},
                :update => {
                  '$inc' => { :tries => 1 },
                  '$set' => {
                    :state => 'run',
                    :started_at => Time.now,
                    :worker => worker.id }})
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
        jobs(payload.queue).update({ :_id => payload.id }, '$set' => { :state => 'enq' })
      end

      def clear_worker(payload)
        jobs(payload.queue).update({ :_id => payload.id }, '$set' => { :worker => nil })
      end

      def failed(payload, error)
        doc = jobs(payload.queue).find_and_modify(
          :query => { :_id => payload.id },
          :update => { '$set' => { :state => 'die' }})
        clear_worker payload
        profile doc, :runtime => Time.now - doc['started_at'], :failed => true, :error => { :message => error.message, :backtrace => error.backtrace}
      end

      def completed(payload)
        doc = jobs(payload.queue).find_and_modify(
          :query => { :_id => payload.id },
          :remove => true)
        profile doc, :runtime => Time.now - doc['started_at'], :failed => false
      end

      def profile doc, data={}
        for key in %w(state progress status added_at) do
          doc.delete key
        end
        self['profiling'].insert(data.merge(:payload => doc, :added_at => Time.now))
      end

      def requeue queue, id=nil
        queue, id = queue.queue, queue.id unless id

        logger.debug "Requeuing job #{id}"
        doc = jobs(queue).find_and_modify(
          :query => { :_id => id },
          :update => { '$set' => { :state => 'enq' }})
        return false unless doc

        doc['id'] = doc.delete('_id')
        Payload.new doc
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

      def remove_zombie_workers
        self.workers.each do |w|
          self.unregister_worker(w) unless w.alive?
        end
      end

      def reenqueue_zombie_jobs queues
        self.remove_zombie_workers
        worker_ids = self.workers.map &:id
        queues.each do |queue|
          candidates = jobs(queue).find(:state => 'run').to_a
          candidates.each do |c|
            if c["worker"] && !worker_ids.include?(c["worker"])
              puts "Reenqueuing zombie: #{c.inspect}"
              self.requeue queue, c["_id"]
            end
          end
        end
      end

    private

      def jobs(queue)
        self["queue.#{queue}"]
      end

      def [](name)
        rescue_connection_failure do
          database["qu.#{name}"]
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
