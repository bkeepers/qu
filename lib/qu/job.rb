module Qu
  module Job
    def perform_with_payload payload, *args
      @_qu_payload = payload
      perform *args
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
