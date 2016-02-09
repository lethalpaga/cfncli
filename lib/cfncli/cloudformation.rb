require 'cfncli/cfn_client'
require 'cfncli/stack'
require 'cfncli/logger'
require 'cfncli/event_poller'

require 'waiting'
require 'pp'

module CfnCli
  class CloudFormation
    include CfnClient
    include Loggable

    def initialize
    end

    # Creates a stack and wait for the creation to be finished
    # @param options [Hash] Options for the stack creation 
    #                       (@see http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation/Client.html)
    def create_stack(options, config = nil)
      stack = create_or_update_stack(options, config)
      stack.wait_for_completion
    end

    # Creates a stack if it doesn't exist otherwise update it
    def create_or_update_stack(options, config = nil)
      opts = process_params(options.dup)
      
      stack_name = opts['stack_name']
      
      stack = create_stack_obj(stack_name, config)
      
      if stack.exists?
        stack.update(opts)
      else
        stack.create(opts)
      end
      
      stack
    end

    # List stack events
    def events(stack_name, config)
      stack = create_stack_obj(stack_name, config)
      stack.list_events(EventPoller.new)
    end

    # Converts the 'standard' json stack parameters format to the format
    # expected by the API
    # (see https://blogs.aws.amazon.com/application-management/post/Tx1A23GYVMVFKFD/Passing-Parameters-to-CloudFormation-Stacks-with-the-AWS-CLI-and-Powershell)
    def self.parse_json_params(params)
      params.map do |param|
        {
          parameter_key: param['ParameterKey'],
          parameter_value: param['ParameterValue']
        }
      end
    end

    private

    # Creates a new stack object
    # Mainly useful to mock it in unit tests
    def create_stack_obj(stack_name, config)
      CfnCli::Stack.new(stack_name, config)
    end

    # Process the parameters
    def process_params(opts)
      opts.delete('disable_rollback')
      opts
    end
  end
end
