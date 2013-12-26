require 'spec_helper'

describe Qu::Hooks do
  before do
    class Pirate
      include Qu::Hooks
      define_hooks :pillage, :plunder

      attr_reader :events

      def initialize
        @events = []
      end

      def pillage
        run_hook(:pillage) do
          @events << :pillage
        end
      end

    private

      def drink
        @events << :drink
      end

      def be_merry
        @events << :be_merry
      end

      def rest
        @events << :rest_before
        yield
        @events << :rest_after
      end
    end

    class Captain < Pirate
      def fight_peter_pan
        @events << :fight
        halt
      end
    end
  end

  after do
    Object.send :remove_const, :Captain
    Object.send :remove_const, :Pirate
  end

  let(:captain) { Captain.new }

  describe 'define_hooks' do
    it 'should create an empty chain' do
      Captain.hooks(:pillage).should be_instance_of(Qu::Hooks::Chain)
      Captain.hooks(:pillage).size.should == 0
    end

    it 'should define before, after and around methods' do
      Captain.respond_to?(:before_pillage).should be_true
      Captain.respond_to?(:after_pillage).should be_true
      Captain.respond_to?(:around_pillage).should be_true
    end
  end

  describe 'before_hook' do
    it 'should add hook with given method' do
      Captain.before_pillage :drink
      captain.pillage
      captain.events.should == [:drink, :pillage]
    end

    it 'should add hook with multiple methods' do
      Captain.before_pillage :drink, :be_merry
      captain.pillage
      captain.events.should == [:drink, :be_merry, :pillage]
    end

    it 'should inherit hooks from parent class' do
      Captain.before_pillage :be_merry
      Pirate.before_pillage :drink

      captain.pillage
      captain.events.should == [:drink, :be_merry, :pillage]
    end
  end

  describe 'after_hook' do
    it 'should add hook with given method' do
      Captain.after_pillage :drink
      captain.pillage
      captain.events.should == [:pillage, :drink]
    end

    it 'should add hook with multiple methods' do
      Captain.after_pillage :drink, :be_merry
      captain.pillage
      captain.events.should == [:pillage, :be_merry, :drink]
    end

    it 'should run declared hooks in reverse order' do
      Captain.after_pillage :drink
      Captain.after_pillage :be_merry
      captain.pillage
      captain.events.should == [:pillage, :be_merry, :drink]
    end
  end

  describe 'around_hook' do
    it 'should add hook with given method' do
      Captain.around_pillage :rest
      captain.pillage
      captain.events.should == [:rest_before, :pillage, :rest_after]
    end

    it 'should maintain order with before and after hooks' do
      Captain.around_pillage :rest
      Captain.before_pillage :drink
      Captain.after_pillage :be_merry
      captain.pillage
      captain.events.should == [:rest_before, :drink, :pillage, :be_merry, :rest_after]
    end

    it 'should halt chain if it does not yield' do
      Captain.around_pillage :drink
      Captain.before_pillage :be_merry
      captain.pillage
      captain.events.should == [:drink]
    end
  end

  describe 'run_hook' do
    it 'should call block when no hooks are declared' do
      captain.pillage
      captain.events.should == [:pillage]
    end

    it 'should pass args to method' do
      Captain.before_pillage :drink
      captain.should_receive(:drink).with(:rum)
      captain.run_hook(:pillage, :rum) { }
    end

    describe 'with a halt before' do
      let(:captain)  { Captain.new }

      before do
        Captain.before_pillage :fight_peter_pan, :drink
      end

      it 'should not call other hooks' do
        captain.should_not_receive :drink
        captain.run_hook(:pillage) {}
      end

      it 'should not invoke block' do
        called = false
        captain.run_hook(:pillage) { called = true }
        called.should be_false
      end
    end

    describe 'with a halt after' do
      let(:captain)  { Captain.new }

      before do
        Captain.after_pillage :drink, :fight_peter_pan
      end

      it 'should not call other hooks' do
        captain.should_not_receive :drink
        captain.run_hook(:pillage) {}
      end

      it 'should invoke block' do
        called = false
        captain.run_hook(:pillage) { called = true }
        called.should be_true
      end
    end
  end
end
