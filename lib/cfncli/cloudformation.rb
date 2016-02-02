require 'cfncli/cfn_client'
require 'cfncli/stack'

require 'waiting'
require 'pp'

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
      resp = cfn.create_stack(options)
      stack = CfnCli::Stack.new(resp.name)

      Waiting.wait(max_attempts: @retries, interval: @interval) do |waiter|
        waiter.done if stack.finished?
      end
      stack.succeeded?
    rescue RuntimeError => e
      false
    end
  end
end
