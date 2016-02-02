require 'aws-sdk'

module CfnCli
  module CfnClient
    # Clouformation Resource
    # This is used to interact with the CloudFormation API
    # @see http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation/Resource.html
    def cfn
      @resource ||= Aws::CloudFormation::Resource.new
    end
  end
end
