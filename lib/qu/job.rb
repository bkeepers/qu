module Qu
  class Job
    attr_accessor :id

    def self.queue(name = nil)
      @queue = name.to_s if name
      @queue ||= 'default'
    end

    def self.with(*params)
      Class.new(Qu::Job) do
        attr_reader *params

        class_eval <<-EOF, __FILE__, __LINE__
          def initialize(#{params.join(', ')})
            #{params.map {|p| "@#{p}"}.join(', ')} = #{params.join(', ')}
          end
        EOF
      end
    end

    def self.load(id, class_name, args)
      constantize(class_name).new(*args).tap {|job| job.id = id }
    end

  protected

    def self.constantize(class_name)
      constant = Object
      class_name.split('::').each do |name|
        constant = constant.const_get(name) || constant.const_missing(name)
      end
      constant
    end


  end
end