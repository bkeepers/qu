require 'qu/backend/redis'

class RunnerJob < Qu::Job
end

class RedisPusherJob < Qu::Job

  def initialize(list, value)
    @list = list
    @value = value
  end

  def perform
    self.class.client.lpush(@list, @value)
  end

  def self.client
    @client ||= Qu::Backend::Redis.create_connection("qu-test")
  end

end

class SleepJob < Qu::Job

  def initialize(sleep_time = 5)
    @sleep = sleep_time
  end

  def perform
    sleep(@sleep)
  end

end

shared_examples_for 'a runner interface' do

  let(:payload) { Qu::Payload.new(:klass => RunnerJob) }

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