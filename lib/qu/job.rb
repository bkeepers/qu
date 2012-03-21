module Qu
  class Job
    def initialize payload
      @_qu_payload = payload
    end

    def progress value
      Qu.backend.progress @_qu_payload, value
    end

    def status msg
      Qu.backend.status @_qu_payload, msg
      msg
    end
  end
end
