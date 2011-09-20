## Features

* Multiple backends (redis, mongo, sql)
* Resque-like API
* …

## Installation

    gem 'qu-redis'

    Qu.configure do |c|
      c.connection = Redis.new
      c.fork       = false
      c.poll       = 20 # for backends that need to poll instead of blocking
    end

## API

    class ProcessPresentation < Qu::Job.new(:)
      @queue = :mailers

      def self.perform(presentation_id)
        presentation = Presentation.find(presentation_id)
        # work here
      end
    end

    job_id = Qu.enqueue ProcessPresentation, @presentation.id

    Qu.length('presentations')
    Qu.work_off # work off all jobs until there are none
    Qu.clear

    ProcessPresentation.create(:presentation_id => 1)

    Qu::Worker.new(*%w(presentations slides *)).start # or work_off

## ToDo

* add job back on queue when worker dies
* configurable exception handling
* callbacks (enqueue, process, error)
* make poll timer configurable
* logger
* autoconfigure heroku connections
* API compatibility with Resque.reserve(queue)
* Job.create