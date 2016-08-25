module CfnCli
  class EventStreamer
    require 'cfncli/config'

    attr_reader :stack
    attr_reader :config

    def initialize(stack, config = nil)
      @stack = stack
      @config = config || default_config
      @seen_events = []
    end

    def default_config
      Config::CfnClient.new
    end

    # Wait for events. This will exit when the
    # stack reaches a finished state
    # @yields [CfnEvent] Events for the stack
    def each_event(&block)
      Waiting.wait(interval: config.interval, max_attempts: config.retries) do |waiter|
        list_events(&block)
        waiter.done if stack.finished?
      end
    end

    def list_events(&block)
      events = []
      @next_token = stack.events(@next_token).each { |event| events << event }
      events.sort { |a, b| a.timestamp <=> b.timestamp }.each do |event|
        yield event unless seen?(event) if block_given?
      end
    rescue Aws::CloudFormation::Errors::ServiceError => e
      raise unless e.class.name == 'Aws::CloudFormation::Errors::Throttling'
    end

    # Mark all the existing events as 'seen'
    def reset_events
      list_events do; end
    end

    private

    attr_accessor :seen_events

    # Indicates if an event has already been seen
    def seen?(event)
      res = seen_events.include? event.id
      seen_events << event.id
      res
    end
  end
end
