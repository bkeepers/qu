require 'qu/queues/redis'

class RunnerJob < Qu::Job
  queue :default
end

class RedisPusherJob < Qu::Job
  queue :redis

  def self.client
    @client ||= Qu.queues[:redis].connection
  end

  def initialize(list, value)
    @list = list
    @value = value
  end

  def perform
    self.class.client.lpush(@list, @value)
  end
end

shared_examples_for 'a runner interface' do
  let(:payload) { Qu::Payload.new(:klass => RunnerJob) }

  before do
    Qu.register :default, Qu::Queues::Memory.new
  end

  it 'can run a payload' do
    subject.run(double("worker"), payload)
  end

  it 'can check if if it is full' do
    subject.full?
  end

  it 'can be stopped' do
    subject.stop
  end
end

shared_examples_for 'a single job runner' do
  let(:list) { 'push-test-list' }
  let(:payload) { Qu::Payload.new(:klass => RedisPusherJob, :args => [list, '1']) }
  let(:timeout) { 5 }

  before do
    Qu.register :redis, Qu::Queues::Redis.new
    RedisPusherJob.client.del(list)
  end

  def expect_values(*args)
    timeout.times do
      break unless subject.full?
      sleep(1)
    end

    result = RedisPusherJob.client.lrange(list, 0, -1)
    if result.size == args.size
      return expect(result).to eq(args)
    end
  end

  it 'can execute a payload' do
    subject.run(double('worker'), payload)
    expect_values('1')
  end
end
