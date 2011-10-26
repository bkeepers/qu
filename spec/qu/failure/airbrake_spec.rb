require 'spec_helper'

require 'qu-airbrake'

describe Qu::Failure::Airbrake do

  let(:job) { Qu::Payload.new(:id => '123', :klass => SimpleJob, :args => ['987']) }

  describe ".extra_stuff" do
    it 'should return job data' do
      described_class.extra_stuff(job).should == {
        :parameters => {
          :id     => '123',
          :queue  => 'default',
          :args   => ['987'],
          :class  => 'SimpleJob'
        }
      }
    end
  end

  describe '.create' do
    let(:exception) { Exception.new }
    
    it 'should send error' do
      ::Airbrake.should_receive(:notify_or_ignore).with(exception, described_class.extra_stuff(job))
      described_class.create(job, exception)
    end
  end
end
