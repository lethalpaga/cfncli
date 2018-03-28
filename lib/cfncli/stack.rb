require 'cfncli/cfn_client'
require 'cfncli/logger'
require 'cfncli/config'
require 'cfncli/event_streamer'
require 'cfncli/event'
require 'cfncli/states'
require 'thread'
require 'concurrent/array'
require 'waiting'
require 'aws-sdk-cloudformation'

module CfnCli
  class Stack
    include CfnCli::CfnClient
    include CfnCli::CfnStates
    include Loggable

    attr_reader :stack_name
    attr_reader :child_stacks

    class StackNotFoundError < StandardError; end

    def initialize(stack_name, config = nil)
      @stack = nil
      @stack_id = nil
      @stack_name = stack_name
      @config = config || default_config
      @child_stacks = Concurrent::Array.new

      @retry_limit = @config.aws_retry_limit
      @retry_backoff = @config.aws_retry_backoff
    end

    def default_config
      Config::CfnClient.new
    end

    def fail_on_noop?
      @config.fail_on_noop
    end

    def stack_id
      @stack_id || @stack_name
    end

    def stack
      fetch_stack
    end

    def exists?
      stack.exists?
    end

    # Creates a new stack
    # @param opts Hash containing the options for `create_stack`
    #             (see http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation/Resource.html#create_stack-instance_method)
    def create(opts)
      logger.debug "Creating stack #{stack_name} (#{opts.inspect})"
      @stack = cfn.create_stack(opts)
      stack.wait_until_exists
      @stack_id = stack.stack_id
    end

    # Updates an existing stack
    # @param opts Hash containing the options for `update_stack`
    #             (see http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation/Client.html#update_stack-instance_method)
    def update(opts)
      logger.debug "Updating stack #{stack_name} (#{opts.inspect})"
      resp = cfn.client.update_stack(opts)
      @stack_id = resp.stack_id
    rescue Aws::CloudFormation::Errors::ValidationError => e
      unless !fail_on_noop? && e.message.include?('No updates are to be performed')
        raise e
      end
    end

    # Deletes an existing stack
    def delete(opts, config)
      logger.debug "Deleting stack #{opts.inspect}"
      # Always use the real stack ID as the stack won't be available once deleted
      id = fetch_stack_id
      cfn.client.delete_stack(stack_name: id)
    end

    # Waits for a stack to be in a finished state
    # @return A boolean indicating if the operation was succesful
    def wait_for_completion
      Waiting.wait(max_attempts: @config.retries, interval: @config.interval) do |waiter|
        waiter.done if finished?
      end
      succeeded?
    rescue Waiting::TimedOutError => e
      logger.error "Timed out while waiting for the stack #{inspect} to be created(#{e.message})"
      false
    end

    # List all events in real time
    # @param poller [CfnCli::Poller] Poller class to display events
    def list_events(poller, streamer = nil, config = nil, event_prefix = nil, list_nested_events = true)
      @event_listing_thread = Thread.new do
        streamer ||= EventStreamer.new(self, config)
        streamer.each_event do |event|
          if list_nested_events && Event.new(event).child_stack_create_event?
            track_child_stack(event.physical_resource_id, event.logical_resource_id, poller)
          end
          poller.event(event, event_prefix)
        end
      end
    end

    # Get the events from the cfn stack
    def events(next_token = nil)
      stack.events(next_token: next_token)
    end

    # Is this stack currently listing events
    def listing_events?
      !@event_listing_thread.nil? && @event_listing_thread.alive?
    end

    # Indicates if the stack is in a finished state
    def finished?
      return false if stack.nil?
      finished_states.include?(stack.stack_status)
    end

    # Indicates if the stack is in a successful state
    def succeeded?
      res = success_states.include? stack.stack_status
      return false if stack.nil?
      res
    end

    # Indicates if the stack is in a transition state
    def in_progress?
      return false if stack.nil?
      transitive_states.include? stack.stack_status
    end

    # Gets stack id from the cfn API
    def fetch_stack_id
      @stack = cfn.stack(stack_id)
      @stack_id = @stack.stack_id
      @stack_id
    end

    private

    # Gets stack info from the cfn API
    def fetch_stack
      @stack = cfn.stack(stack_id)
      @stack
    end

    def track_child_stack(child_stack_id, logical_id, poller)
      child_stack = Stack.new child_stack_id, @config
      @child_stacks << child_stack
      logger.debug "Listing events for child stack #{stack.stack_name}"
      child_stack.list_events poller, nil, @config, logical_id
    end
  end
end
