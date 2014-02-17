module Qu
  module Hooks
    def self.included(base)
      base.extend ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def define_hooks(*hooks)
        hooks.each do |hook|
          define_hook_by_kinds(hook, *%w(before after around))
        end
      end

      def define_hook_by_kinds( hook, *kinds )
        kinds.each do |kind|
          class_eval <<-end_eval, __FILE__, __LINE__
            def self.#{kind}_#{hook}(*methods)
              hooks(:#{hook}).add(:#{kind}, *methods)
            end
          end_eval
        end
      end

      def hooks(name)
        @hooks ||= {}
        @hooks[name] ||= Chain.new
      end
    end

    module InstanceMethods

      def run_hook(name, *args, &block)
        find_hooks_for(name).run(self, args, &block)
      end

      def run_before_hook( name, *args )
        run_hook_by_type(name, *args, :before)
      end

      def run_after_hook( name, *args )
        run_hook_by_type(name, *args, :after)
      end

      def find_hooks_for(name)
        if self.class.superclass < Qu::Hooks
          self.class.superclass.hooks(name).dup.concat self.class.hooks(name)
        else
          self.class.hooks(name)
        end
      end

      def halt
        throw :halt
      end

      private

      def run_hook_by_type( name, type, *args, &block )
        if hook = find_hooks_for(name).find { |hook| hook.type == type }
          hook.call(self, args, &block)
        end
      end

    end

    class Chain < Array
      def run(object, args, &block)
        catch :halt do
          reverse.inject(block) do |chain, hook|
            lambda { hook.call(object, args, &chain) }
          end.call
        end
      end

      def add(kind, *methods)
        methods.each {|method| self << Hook.new(kind, method) }
      end

    end

    class Hook
      attr_reader :type, :method

      def initialize(type, method)
        @type, @method = type, method
      end

      def call(obj, args, &chain)
        if type == :around
          obj.send method, *args, &chain
        else
          obj.send method, *args if type == :before
          chain.call if chain
          obj.send method, *args if type == :after
        end
      end
    end
  end
end