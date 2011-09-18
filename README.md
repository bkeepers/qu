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

    Qu.length('presentations')
    Qu.work_off # work off all jobs until there are none
    Qu.clear

    class ProcessPresentation < Qu::Job.new(:presentation_id)
      queue :mailers

      def perform
        presentation = Presentation.find(presentation_id)
        # work here
      end
    end

    job_id = Qu.enqueue ProcessPresentation, @presentation.id

    ProcessPresentation.create(:presentation_id => 1)

    Qu::Worker.new(*%w(presentations slides *)).start # or work_off

## ToDo

* worker.work
* add job back on queue when worker dies
* use queue specified in job class
* configurable exception handling
* callbacks (enqueue, process, error)
* make poll timer configurable
* logger
* autoconfigure heroku connections
