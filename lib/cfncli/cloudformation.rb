require 'cfncli/cfn_client'
require 'cfncli/stack'
require 'cfncli/logger'

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

    def create_or_update_stack(options, config = nil)
      opts = process_params(options.dup)
      
      stack_name = opts['stack_name']
      
      stack = create_stack_obj(stack_name, config)
      
      logger.debug "The stack #{stack.stack_name} #{stack.exists? ? 'exists': 'does not exist'}"
      if stack.exists?
        stack.update(opts)
      else
        stack.create(opts)
      end
      
      stack
    end

    def create_stack_obj(stack_name, config)
      CfnCli::Stack.new(stack_name, config)
    end

    def process_params(opts)
      opts.delete('disable_rollback')
      opts
    end
  end
end
