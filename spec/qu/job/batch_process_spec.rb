require 'spec_helper'

class SimpleBatchJob < Qu::Job
  include Qu::Job::BatchProcess
end

describe Qu::Job::BatchProcess do
  let(:job) { SimpleBatchJob.new }

  it 'responds to batch_job? with true' do
    SimpleBatchJob.batch_job?.should == true
  end

  describe '.batch' do
    it 'returns an empty array without a payload' do
      job.batch.should == []
    end

    it 'returns payload if payload is a collection' do
      job.payload = [1]
      job.batch.should == [1]
    end

    it 'returns an array if payload is not a collection' do
      job.payload = 1
      job.batch.should == [1]
    end
  end

  describe '.each' do
    it 'yields args for a single payload' do
      job.payload = Qu::Payload.new(:klass => job.class, :args => [1])
      job_args = []
      job.each do |*args|
        job_args << args
      end
      job_args.should == [[1]]
    end

    it 'yields args for multiple payloads' do
      batch = []
      5.times do |i|
        batch << Qu::Payload.new(:klass => job.class, :args => [i, 'a'])
      end
      job.payload = batch
      job_args = []
      job.each do |*args|
        job_args << args
      end
      job_args.should == [[0, 'a'], [1, 'a'], [2, 'a'], [3, 'a'], [4, 'a']]
    end

    it 'supports enumerable methods' do
      batch = []
      5.times do |i|
        batch << Qu::Payload.new(:klass => job.class, :args => [i, 'a'])
      end
      job.payload = batch
      job_args = job.collect.to_a.should == [[0, 'a'], [1, 'a'], [2, 'a'], [3, 'a'], [4, 'a']]
    end
  end

  describe '.each_payload' do
    it 'yields a single payload' do
      job.payload = Qu::Payload.new(:klass => job.class, :args => [1])
      payloads = []
      job.each_payload do |payload|
        payloads << payload
      end
      payloads.should == [job.payload]
    end

    it 'yields multiple payloads' do
      batch = []
      5.times do |i|
        batch << Qu::Payload.new(:klass => job.class, :args => [i])
      end
      job.payload = batch
      payloads = []
      job.each_payload do |payload|
        payloads << payload
      end
      payloads.should == batch
    end
  end
end
