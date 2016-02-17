require 'cfncli/states'

module CfnCli
  class Event
    include CfnStates

    attr_reader :event

    def initialize(event)
      @event = event
    end

    def status
      event.resource_status
    end

    def color
      return :green if succeeded?
      return :yellow if in_progress?
      return :red if failed?
    end

    def to_s
      "#{event.timestamp} #{event.resource_status} #{event.resource_type} #{event.logical_resource_id} #{event.resource_status_reason}"
    end
  end
end
