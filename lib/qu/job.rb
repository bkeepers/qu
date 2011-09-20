module Qu
  class Job
    attr_accessor :id, :klass, :args

    def initialize(id, klass, args)
      @id, @args = id, args

      @klass = klass.is_a?(Class) ? klass : constantize(klass)
    end

    def queue
      (klass.instance_variable_get(:@queue) || 'default').to_s
    end

    def perform
      klass.perform(*args)
    end

  protected

    def constantize(class_name)
      constant = Object
      class_name.split('::').each do |name|
        constant = constant.const_get(name) || constant.const_missing(name)
      end
      constant
    end


  end
end