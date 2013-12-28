require 'spec_helper'
require 'qu/instrumentation/statsd'

describe Qu::Instrumentation::StatsdSubscriber do
  let(:statsd_client) { Statsd.new }
  let(:socket) { FakeUDPSocket.new }

  before do
    Qu.backend = Qu::Backend::Redis.new
    Qu.clear
    @original_instrumenter = Qu.instrumenter
    Qu.instrumenter = ActiveSupport::Notifications
    described_class.client = statsd_client
    Thread.current[:statsd_socket] = socket
  end

  after do
    Qu.instrumenter = @original_instrumenter
    described_class.client = nil
    Thread.current[:statsd_socket] = nil
  end

  def assert_timer(metric)
    regex = /#{Regexp.escape metric}\:\d+\|ms/
    socket.buffer.detect { |op| op.first =~ regex }.should_not be_nil
  end

  def assert_counter(metric)
    socket.buffer.detect { |op| op.first == "#{metric}:1|c" }.should_not be_nil
  end

  it "instruments push" do
    payload = SimpleJob.create
    assert_timer "qu.push"
    assert_timer "qu.push.SimpleJob"
  end

  it "instruments perform" do
    payload = SimpleJob.create
    payload.perform
    assert_timer "qu.perform"
    assert_timer "qu.perform.SimpleJob"
  end

  it "instruments complete" do
    payload = SimpleJob.create
    payload.perform
    assert_timer "qu.complete"
    assert_timer "qu.complete.SimpleJob"
  end

  it "instruments abort" do
    payload = SimpleJob.create
    payload.job.stub(:perform).and_raise(Qu::Worker::Abort.new)
    begin
      payload.perform
      flunk # should not get here
    rescue Qu::Worker::Abort
      assert_timer "qu.abort"
      assert_timer "qu.abort.SimpleJob"
    end
  end

  it "instruments failure" do
    payload = SimpleJob.create
    payload.job.stub(:perform).and_raise(StandardError.new)
    begin
      payload.perform
      flunk # should not get here
    rescue => exception
      assert_timer "qu.failure"
      assert_timer "qu.failure.SimpleJob"
    end
  end
end
