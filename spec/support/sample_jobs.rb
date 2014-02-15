class MessageQueue

end

class PriorityJob < Qu::Job
  queue :priority

  def initialize( message )
    @message
  end



end

class NonPriorityJob < Qu::Job
  queue :not_priority
end