require 'cfncli/cfn_client'

module CfnCli
  class Stack
    include CfnCli::CfnClient
    
    def initialize(stack_name)
      @stack_name = stack_name
    end

    def stack
      @stack = cfn.stack(@stack_name)
      fail ArgumentError, "Stack #{@stack_name} not found" unless @stack
      @stack
    end

    def finished?
      finished_states.include? stack.stack_status
    end

    def succeeded?
      success_states.include? stack.stack_status
    end

    def in_progress?
      transitive_states.include? stack.stack_status
    end

    def failed?
      !succeeded? && !in_progress?
    end

    def finished_states
      states.select do |state|
        res = false
        res ||= state.end_with? 'FAILED'
        res ||= state.end_with? 'COMPLETE'
      end
    end

    def transitive_states
      states - finished_states
    end

    def success_states
      [
        'CREATE_COMPLETE',
        'DELETE_COMPLETE',
        'UPDATE_COMPLETE'
      ]
    end

    def failed_states
      states - success_states - transitive_states
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
  end
end
