require 'cfncli/cfn_client'
require 'cfncli/logger'
require 'cfncli/config'
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
      @stack || fetch_stack
    end

    def exists?
      stack.exists?
    end

    def create(opts)
      logger.debug "Creating a stack (#{opts.inspect})"
      @stack = cfn.create_stack(opts)
      stack.wait_until_exists
      @stack_id = stack.stack_id
    end

    def update(opts)
      logger.debug "Updating a stack (#{opts.inspect})"
      resp = cfn.client.update_stack(opts)
      @stack_id = resp.stack_id
    rescue Aws::CloudFormation::Errors::ValidationError => e
      unless !fail_on_noop? && e.message.include?('No updates are to be performed')
        raise e
      end
    end

    def wait_for_completion
      Waiting.wait(max_attempts: @config.retries, interval: @config.interval) do |waiter|
        waiter.done if finished?
      end
      succeeded?
    rescue Waiting::TimedOutError => e
      logger.error "Timed out while waiting for the stack #{inspect} to be created(#{e.message})"
      false
    end
 
    def finished?
      logger.debug "Checking if stack exists, stack=#{stack}, status=#{stack.stack_status unless stack.nil?}"
      return false if stack.nil?
      finished_states.include? stack.stack_status
    end

    def succeeded?
      res = success_states.include? stack.stack_status
      logger.debug "Checking if stack #{stack} has succeded (#{res})"
      return false if stack.nil?
      res
    end

    def in_progress?
      return false if stack.nil?
      transitive_states.include? stack.stack_status
    end

    def failed?
      !succeeded? && !in_progress?
    end

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

    def success_states
      [
        'CREATE_COMPLETE',
        'DELETE_COMPLETE',
        'UPDATE_COMPLETE'
      ]
    end

    def transitive_states
      states.select do |state|
        state.end_with? 'IN_PROGRESS'
      end
    end

    def finished_states
      states - transitive_states
    end

    def failed_states
      states - success_states - transitive_states
    end

    private

    def fetch_stack
      @stack = cfn.stack(stack_id)
      @stack
    end
  end
end
