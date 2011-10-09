module Qu
  module Hooks
    def self.included(base)
      base.extend ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def define_hooks(*hooks)
        hooks.each do |hook|
          %w(before after around).each do |kind|
            class_eval <<-end_eval, __FILE__, __LINE__
              def self.#{kind}_#{hook}(*methods)
                hooks(:#{hook}).add(:#{kind}, *methods)
              end
            end_eval
          end
        end
      end

      def hooks(name)
        @hooks ||= {}
        @hooks[name] ||= Chain.new
      end
    end

    module InstanceMethods
      def run_hook(name, *args, &block)
        hooks = if self.class.superclass < Qu::Hooks
          self.class.superclass.hooks(name).dup.concat self.class.hooks(name)
        else
          self.class.hooks(name)
        end

        hooks.run(self, args, &block)
      end

      def halt
        throw :halt
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
          chain.call
          obj.send method, *args if type == :after
        end
      end
    end
  end
end