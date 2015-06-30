module InstrumentationSpecHelpers
  # Public: Subscribe to events by name and return array.
  #
  # name - The String name of the events to subscribe to.
  # block - The block to call that should emit events.
  def events_for(name, &block)
    events = []

    begin
      original_instrumenter = Qu.instrumenter
      Qu.instrumenter = ActiveSupport::Notifications
      callback = lambda { |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      }
      ActiveSupport::Notifications.subscribed(callback, name) do
        yield
      end
    ensure
      Qu.instrumenter = original_instrumenter
    end

    events
  end
end
