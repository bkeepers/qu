require 'spec_helper'
require 'qu/instrumentation/statsd'

describe Qu::Instrumentation::StatsdSubscriber do
  let(:statsd_client) { Statsd.new }
  let(:socket) { FakeUDPSocket.new }

  before do
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

  it "instruments pop" do
    worker = Qu::Worker.new(SimpleJob.queue)
    worker.work
    assert_timer "qu.op.pop"
    assert_timer "qu.queue.#{SimpleJob.queue}.pop"
  end

  it "instruments push" do
    payload = SimpleJob.create
    assert_timer "qu.op.push"
    assert_timer "qu.job.SimpleJob.push"
    assert_timer "qu.queue.#{SimpleJob.queue}.push"
  end

  it "instruments perform" do
    payload = SimpleJob.create
    payload.perform
    assert_timer "qu.op.perform"
    assert_timer "qu.job.SimpleJob.perform"
  end

  it "instruments complete" do
    payload = SimpleJob.create
    payload.perform
    assert_timer "qu.op.complete"
    assert_timer "qu.job.SimpleJob.complete"
  end

  it "instruments abort" do
    payload = SimpleJob.create
    payload.job.stub(:perform).and_raise(Qu::Worker::Abort.new)
    begin
      payload.perform
      flunk # should not get here
    rescue Qu::Worker::Abort
      assert_timer "qu.op.abort"
      assert_timer "qu.job.SimpleJob.abort"
    end
  end

  it "instruments fail" do
    payload = SimpleJob.create
    payload.job.stub(:perform).and_raise(StandardError.new)
    begin
      payload.perform
      flunk # should not get here
    rescue => exception
      assert_timer "qu.op.fail"
      assert_timer "qu.job.SimpleJob.fail"
    end
  end

  it "instruments failure report" do
    payload = SimpleJob.create
    payload.job.stub(:perform).and_raise(StandardError.new)
    begin
      payload.perform
      flunk # should not get here
    rescue => exception
      assert_timer "qu.op.failure_report"
      assert_timer "qu.job.SimpleJob.failure_report"
    end
  end
end
