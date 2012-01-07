# Qu

Qu is a Ruby library for queuing and processing background jobs. It is heavily inspired by delayed_job and Resque.

Qu was created to overcome some shortcomings in the existing queuing libraries that we experienced at [Ordered List](http://orderedlist.com) while building [SpeakerDeck](http://speakerdeck.com), [Gaug.es](http://get.gaug.es) and [Harmony](http://get.harmonyapp.com). The advantages of Qu are:

* Multiple backends (redis, mongo)
* Jobs are requeued when worker is killed
* Resque-like API

## Information & Help

* Find more information on the [Wiki](https://github.com/bkeepers/qu/wiki).
* Post to the [Google Group](http://groups.google.com/group/qu-users) for help or questions.
* See the [issue tracker](https://github.com/bkeepers/qu/issues) for known issues or to report an issue.

## Installation

### Rails 3

Decide which backend you want to use and add the gem to your `Gemfile`.

``` ruby
gem 'qu-redis'
```

That's all you need to do!

### Rails 2

Decide which backend you want to use and add the gem to `config.gems` in `environment.rb`:

``` ruby
config.gem 'qu-redis'
````

To load the rake tasks, add the following to your `Rakefile`:

``` ruby
require 'qu/tasks'
```

## Usage

Jobs are any class that responds to the `.perform` method:

``` ruby
class ProcessPresentation
  def self.perform(presentation_id)
    presentation = Presentation.find(presentation_id)
    presentation.process!
  end
end
```

You can add a job to the queue by calling the `enqueue` method:

``` ruby
job = Qu.enqueue ProcessPresentation, @presentation.id
puts "Enqueued job #{job.id}"
```

Any additional parameters passed to the `enqueue` method will be passed on to the `perform` method of your job class. These parameters will be stored in the backend, so they must be simple types that can easily be serialized and unserialized. So don't try to pass in an ActiveRecord object.

Processing the jobs on the queue can be done with a Rake task:

``` sh
$ bundle exec rake qu:work
```

You can easily inspect the queue or clear it:

``` ruby
puts "Jobs on the queue:", Qu.length
Qu.clear
```

### Queues

The `default` queue is used, um…by default. Jobs that don't specify a queue will be placed in that queue, and workers that don't specify a queue will work on that queue.

However, if you have some background jobs that are more or less important, or some that take longer than others, you may want to consider using multiple queues. You can have workers dedicated to specific queues, or simply tell all your workers to work on the most important queue first.

Jobs can be placed in a specific queue by setting the queue variable:

``` ruby
class CallThePresident
  @queue = :urgent

  def self.perform(message)
    # …
  end
end
```

You can then tell workers to work on this queue by passing an environment variable

``` sh
$ bundle exec rake qu:work QUEUES=urgent,default
```

Note that if you still want your worker to process the default queue, you must specify it. Queues will be process in the order they are specified.

You can also get the length or clear a specific queue:

``` ruby
Qu.length(:urgent)
Qu.clear(:urgent)
```

## Configuration

Most of the configuration for Qu should be automatic. It will also automatically detect ENV variables from Heroku for backend connections, so you shouldn't need to do anything to configure the backend.

However, if you do need to customize it, you can by calling the `Qu.configure`:

``` ruby
Qu.configure do |c|
  c.connection  = Redis::Namespace.new('myapp:qu', :redis => Redis.connect)
  c.logger      = Logger.new('log/qu.log')
end
```

## Tests

If you prefer to have jobs processed immediatly in your tests, there is an `Immediate` backend that will perform the job instead of enqueuing it. In your test helper, require qu-immediate:

``` ruby
require 'qu-immediate'
```

## Why another queuing library?

Resque and delayed_job are both great, but both of them have shortcomings that can be frustrating in production applications.

delayed_job was a brilliantly simple pioneer in the world of database-backed queues. While most asynchronous queuing systems were tending toward overly complex, it made use of your existing database and just worked. But there are a few flaws:

* Occasionally fails silently.
* Use of priority instead of separate named queues.
* Contention in the ActiveRecord backend with multiple workers. Occasionally the same job gets performed by multiple workers.

Resque, the wiser relative of delayed_job, fixes most of those issues. But in doing so, it forces some of its beliefs on you, and sometimes those beliefs just don't make sense for your environment. Here are some of the flaws of Resque:

* Redis is a great queue backend, but it doesn't make sense for every environment.
* Workers lose jobs when they are forced to quit. This has especially been an issue on Heroku.
* Forking before each job prevents memory leaks, but it is terribly inefficient in environments with a lot of fast jobs (the resque-jobs-per-fork plugin alleviates this)

Those shortcomings lead us to write Qu. It is not perfect, but we hope to overcome the issues we faced with other queuing libraries.

## Contributing

If you find what looks like a bug:

1. Search the [mailing list](http://groups.google.com/group/qu-users) to see if anyone else had the same issue.
2. Check the [GitHub issue tracker](http://github.com/bkeepers/qu/issues/) to see if anyone else has reported issue.
3. If you don't see anything, create an issue with information on how to reproduce it.

If you want to contribute an enhancement or a fix:

1. Fork the project on GitHub.
2. Make your changes with tests.
3. Commit the changes without making changes to the Rakefile, Gemfile, gemspec, or any other files that aren't related to your enhancement or fix
4. Send a pull request.
