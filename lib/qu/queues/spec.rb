require "qu/queues/memory"

class SimpleJob < Qu::Job
  queue :default
end

shared_examples_for 'a queue interface' do
  before do
    Qu.register :default, Qu::Queues::Memory.new
    Qu.register :default, subject
  end

  let(:payload) { Qu::Payload.new(:klass => SimpleJob) }

  it "can push a payload" do
    subject.push payload
  end

  it "can complete a payload" do
    subject.complete payload
  end

  it "can abort a payload" do
    subject.abort payload
  end

  it "can fail a payload" do
    subject.fail payload
  end

  it "can pop from a queue" do
    subject.pop
  end

  it "can get size of a queue" do
    subject.size
  end

  it "can clear a queue" do
    subject.clear
  end

  it 'can reconnect' do
    subject.reconnect
  end
end

shared_examples_for 'a queue' do
  let(:payload) { Qu::Payload.new(:klass => SimpleJob) }

  before do
    Qu.register :default, subject
    subject.clear
  end

  describe 'push' do
    it 'should return a payload' do
      subject.push(payload).should be_instance_of(Qu::Payload)
    end

    it 'should set the payload id' do
      subject.push(payload)
      payload.id.should_not be_nil
    end

    it 'should add a job to the queue' do
      subject.push(payload)
      subject.size.should == 1
    end

    it 'should assign a different job id for the same job pushed multiple times' do
      first = subject.push(payload).id
      second = subject.push(payload).id
      first.should_not eq(second)
    end

    it 'should enqueue the attributes for push' do
      payload.should_receive(:attributes_for_push).and_return({})
      subject.push(payload)
    end
  end

  describe 'pop' do
    it 'should return next job' do
      subject.push(payload)
      subject.pop.id.should == payload.id
    end

    it 'should not return an already popped job' do
      subject.push(payload)
      subject.push(payload.dup)
      subject.pop.id.should_not == subject.pop.id
    end

    it 'should properly persist args' do
      payload.args = ['a', 'b']
      subject.push(payload)
      subject.pop.args.should == ['a', 'b']
    end

    it 'should properly persist a hash argument' do
      payload.args = [{:a => 1, :b => 2}]
      subject.push(payload)
      subject.pop.args.should == [{'a' => 1, 'b' => 2}]
    end
  end

  describe 'complete' do
    it 'should be defined and accept payload' do
      subject.complete(payload)
    end
  end

  describe 'abort' do
    before do
      subject.push(payload)
    end

    it 'should add the job back' do
      popped_payload = subject.pop
      popped_payload.id.should == payload.id
      subject.size.should == 0
      subject.abort(popped_payload)
      subject.size.should == 1
    end
  end

  describe 'fail' do
    it 'should be defined and accept payload' do
      subject.fail(payload)
    end
  end

  describe 'size' do
    it 'should return number of jobs' do
      subject.size.should == 0
      subject.push(payload)
      subject.size.should == 1
    end
  end

  describe 'clear' do
    it 'should clear jobs' do
      subject.push(payload)
      subject.size.should == 1
      subject.clear
      subject.size.should == 0
    end
  end

  describe 'connection=' do
    it 'should allow setting the connection' do
      connection = double('a connection')
      subject.connection = connection
      subject.connection.should == connection
    end

    it 'should provide a default connection' do
      subject.connection.should_not be_nil
    end
  end
end
