module CfnCli
  module CfnStates
    # Indicates if the state is finished
    def finished?
      finished_states.include? status
    end

    # Indicates if the state is successful
    def succeeded?
      success_states.include? status
    end

    # Indicates if the state is a transition
    def in_progress?
      transitive_states.include? status
    end

    # Indicates if the state is failed
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
  end
end
