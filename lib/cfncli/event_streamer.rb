module CfnCli
  class EventStreamer
    attr_reader :stack

    def initialize(stack)
      @stack = stack
      @seen_events = []
    end

    # Wait for events. This will exit when the
    # stack reaches a finished state
    # @yields [CfnEvent] Events for the stack
    def each_event
      Waiting.wait do |waiter|
        next_token = stack.events(next_token).each do |event|
          yield event unless seen?(event)
        end

        waiter.done if stack.finished?
      end
    end

    private

    attr_accessor :seen_events

    # Indicates if an event has already been seen
    def seen?(event)
      res = @seen_events.include? event.id
      @seen_events << event.id
      res
    end
  end
end
