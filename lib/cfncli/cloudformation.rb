require 'pp'
require 'cfncli/cfn_client'
require 'waiting'

module CfnCli
  class CloudFormation
    include CfnClient

    attr_accessor :interval, :retries

    def initialize(interval=10, retries=10)
      @interval = 10
      @retries = 10
    end

    # Creates a stack and wait for the creation to be finished
    # @param options [Hash] Options for the stack creation 
    #                       (@see http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation/Client.html)
    def create_stack(options)
      @stack_name = options['stack_name']

      cfn.create_stack(options)

      Waiting.wait(max_attempts: @retries, interval: @interval) do |waiter|
        waiter.done if stack.finished?
      end
      true
    rescue RuntimeError => e
      false
    end

    def stack(stack_name = nil)
      stack_name ||= @stack_name
      @stack ||= CfnCli::Stack.new(stack_name)
      @stack
    end
  end
end
