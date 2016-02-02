require 'aws-sdk'
require 'pp'

module CfnCli
  class CloudFormation
    def initialize

    end

    # Creates a stack and wait for the creation to be finished
    # @param options [Hash] Options for the stack creation 
    #                       (@see http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation/Client.html)
    def create_stack(options)
      puts "Create stack with options #{pp options}"
      cfn.create_stack(options)
    end
   
    # Clouformation Resource
    # This is used to interact with the CloudFormation API
    # @see http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation/Resource.html
    def cfn
      @resource ||= Aws::CloudFormation::Resource.new
    end
  end
end
