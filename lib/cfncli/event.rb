require 'cfncli/states'

module CfnCli
  class Event
    include CfnStates

    attr_reader :event

    RESOURCE_CREATE_INITIATED = 'Resource creation Initiated'.freeze
    AWS_STACK_RESOURCE = 'AWS::CloudFormation::Stack'.freeze

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

    # Check if the current event has the signature of a child stack creation
    def child_stack_create_event?
      return false unless in_progress?
      return false unless event.resource_type == AWS_STACK_RESOURCE
      return false unless event.resource_status_reason == RESOURCE_CREATE_INITIATED
      true
    end

    def to_s
      "#{event.timestamp} #{event.resource_status} #{event.resource_type} #{event.logical_resource_id} #{event.resource_status_reason}"
    end
  end
end
