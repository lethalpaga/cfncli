require 'pp'
require 'cfncli/cfn_client'
require 'waiting'

module CfnCli
  class CloudFormation
    include CfnClient

    def initialize(interval=10, retries=10)
      @interval = 10
      @retries = 10

      Waiting.default_max_attempts = @retries
      Waiting.default_interval = @interval
    end

    # Creates a stack and wait for the creation to be finished
    # @param options [Hash] Options for the stack creation 
    #                       (@see http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation/Client.html)
    def create_stack(options)
      puts "Create stack with options #{pp options}"
      cfn.create_stack(options)
      Waiting.wait do |waiter|
        waiter.done if stack.finished_state?
      end
    end

    def stack(stack_name)
      @stack ||= CfnCli::Stack.new(stack_name)
    end
  end
end
