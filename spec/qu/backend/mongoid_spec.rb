require 'spec_helper'
require 'qu-mongoid'
require 'thread'

describe Qu::Backend::Mongoid do
  it_should_behave_like 'a backend'

  describe 'connection' do
    it 'should default the qu database' do
      subject.connection.should be_instance_of(Moped::Session)
      subject.connection.options[:database].should == 'qu'
    end
    
    it 'should use MONGOHQ_URL from heroku' do
      # Clean up from other tests
      ::Mongoid.sessions[:default]  = nil
      subject.instance_eval {@connection=nil}
      ::Mongoid::Sessions.clear
      
      ENV['MONGOHQ_URL'] = 'mongodb://127.0.0.1:27017/quspec'
      subject.connection.options[:database].should == 'quspec'
      subject.connection.cluster.nodes.first.resolved_address.should == "127.0.0.1:27017"
      ::Mongoid.sessions[:default][:hosts].should include("127.0.0.1:27017")
      
      # Clean up MONGOHQ stuff
      ENV.delete('MONGOHQ_URL')
      subject.instance_eval {@connection=nil}
      ::Mongoid.connect_to('qu')
    end
  end

  describe 'reserve' do
    let(:worker) { Qu::Worker.new }

    describe "on mongo >=2" do
      it 'should return nil when no jobs exist' do
        subject.clear
        Moped::Session.any_instance.should_receive(:command).and_return(nil)
        lambda { subject.reserve(worker, :block => false).should be_nil }.should_not raise_error
      end
    end

    describe 'on mongo <2' do
      it 'should return nil when no jobs exist' do
        subject.clear
        Moped::Session.any_instance.should_receive(:command).and_raise(Moped::Errors::OperationFailure.new(nil, 'test'))
        lambda { subject.reserve(worker, :block => false).should be_nil }.should_not raise_error
      end
    end
  end
end
