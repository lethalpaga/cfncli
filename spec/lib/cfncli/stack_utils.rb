module CfnCli
  module StackUtils
    def describe_stacks_resp(status)
      client.stub_data(:describe_stacks, {
        stacks: [{
          stack_status: status
        }]
      })
    end
  end
end

