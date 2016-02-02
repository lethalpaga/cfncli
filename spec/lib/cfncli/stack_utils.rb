module CfnCli
  module StackUtils
    def base_stack
      {
        stack_id: 'test-stack-id',
        stack_name: 'test-stack',
        creation_time: Time.now
      }
    end

    def update_in_progress_stack
      base_stack.merge(stack_status: 'UPDATE_IN_PROGRESS')
    end

    def update_failed_stack
      base_stack.merge(stack_status: 'UPDATE_FAILED')
    end

    def updated_stack
      base_stack.merge(stack_status: 'UPDATE_COMPLETE')
    end

    def stub_stack(stack)
      {
        describe_stacks: {
          stacks: [
            stack
          ]
        },
        list_stacks: {
          stack_summaries: [
            stack
          ]
        },
        create_stack: {
          stack_name: stack['stack_name']
        }
      }
    end
  end
end

