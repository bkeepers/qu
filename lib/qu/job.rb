module Qu
  module Job
    attr_writer :resume, :_qu_payload

    def progress value
      Qu.backend.progress @_qu_payload, value
    end

    def status msg
      Qu.backend.status @_qu_payload, msg
      msg
    end

    def save state
      Qu.backend.save @_qu_payload, state
    end

    def set data
      Qu.backend.set @_qu_payload, data
    end

    def resume state
    end

    def abort!
    end
  end
end
