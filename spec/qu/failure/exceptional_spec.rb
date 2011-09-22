require 'spec_helper'
require 'qu-exceptional'

describe Qu::Failure::Exceptional do
  let(:job) { Qu::Job.new('123', SimpleJob, ['987']) }

  describe Qu::Failure::Exceptional::ExceptionData do
    subject { Qu::Failure::Exceptional::ExceptionData.new(job, Exception.new) }

    it 'should include job data in the request' do
      subject.extra_stuff.should == {
        'id'    => '123',
        'queue' => 'default',
        'args'  => ['987'],
        'class' => 'SimpleJob'
      }
    end

    it 'should set the framework' do
      subject.framework.should == 'qu'
    end
  end

  describe 'create' do
    context 'with exceptional enabled' do
      before do
        Exceptional::Config.enabled = true
      end

      it 'should send error' do
        Exceptional::Remote.should_receive(:error).with(instance_of(Qu::Failure::Exceptional::ExceptionData))
        described_class.create(job, Exception.new)
      end
    end

    context 'with exceptional disabled' do
      before do
        Exceptional::Config.enabled = false
      end

      it 'should not send error' do
        Exceptional::Remote.should_not_receive(:error)
        described_class.create(job, Exception.new)
      end
    end
  end
end
