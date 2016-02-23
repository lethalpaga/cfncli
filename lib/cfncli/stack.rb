require 'cfncli/cfn_client'
require 'cfncli/logger'
require 'cfncli/config'
require 'cfncli/event_streamer'

require 'waiting'

module CfnCli
  class Stack
    include CfnCli::CfnClient
    include Loggable

    attr_reader :stack_name

    class StackNotFoundError < StandardError; end
    
    def initialize(stack_name, config = nil)
      @stack = nil
      @stack_id = nil
      @stack_name = stack_name
      @config = config || default_config
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
    def list_events(poller, config = nil)
      streamer = EventStreamer.new(self, config)
      streamer.each_event do |event|
        poller.event(event)
      end
    end
     
    # Get the events from the cfn stack
    def events(next_token)
      stack.events(next_token)
    end

    # Indicates if the stack is in a finished state
    def finished?
      return false if stack.nil?
      finished_states.include? stack.stack_status
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

    # Indicates if the stack is in a failed state
    def failed?
      !succeeded? && !in_progress?
    end

    # List of possible states
    def states
      [
        'CREATE_IN_PROGRESS',
        'CREATE_IN_PROGRESS',
        'CREATE_FAILED',
        'CREATE_COMPLETE',
        'ROLLBACK_IN_PROGRESS',
        'ROLLBACK_FAILED',
        'ROLLBACK_COMPLETE',
        'DELETE_IN_PROGRESS',
        'DELETE_FAILED',
        'DELETE_COMPLETE',
        'UPDATE_IN_PROGRESS',
        'UPDATE_COMPLETE_CLEANUP_IN_PROGRESS',
        'UPDATE_COMPLETE',
        'UPDATE_ROLLBACK_IN_PROGRESS',
        'UPDATE_ROLLBACK_FAILED',
        'UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS',
        'UPDATE_ROLLBACK_COMPLETE',
      ]
    end

    # List of successful states
    def success_states
      [
        'CREATE_COMPLETE',
        'DELETE_COMPLETE',
        'UPDATE_COMPLETE'
      ]
    end

    # List of transitive states
    def transitive_states
      states.select do |state|
        state.end_with? 'IN_PROGRESS'
      end
    end

    # List of finished states
    def finished_states
      states - transitive_states
    end

    # List of failed or unknown states
    def failed_states
      states - success_states - transitive_states
    end

    private

    # Gets stack info from the cfn API
    def fetch_stack
      @stack = cfn.stack(stack_id)
      @stack
    end
  end
end
