require 'spec_helper'

describe Qu::PayloadBatch do
  let(:payloads) {[
    Qu::Payload.new(:klass => SimpleJob, :args => [1]),
    Qu::Payload.new(:klass => SimpleJob, :args => [2]),
  ]}

  subject { described_class.new(payloads) }

  it 'takes an array of payloads' do
    subject.size.should == payloads.size
  end

  it 'takes a list of payloads' do
    subject = described_class.new(*payloads)
    subject.size.should == payloads.size
  end

  it 'puts payloads into a batch' do
    subject.batch.should == payloads
  end

  it 'appends to the batch' do
    subject.append(*payloads)
    subject.batch.should == payloads*2
  end

  it 'performs each payload in the batch' do
    payloads.each { |payload| payload.should_receive(:perform) }
    subject.perform
  end

  it 'is enumerable' do
    subject.map { |payload| payload.to_s }.should == payloads.map(&:to_s)
  end
end
