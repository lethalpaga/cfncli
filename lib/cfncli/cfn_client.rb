require 'aws-sdk'

module CfnCli
  module CfnClient

    attr_accessor :stub_responses

    # CloudFormation client
    # @see http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation/Client.html
    def cfn_client
      @@client ||= Aws::CloudFormation::Client.new(stub_responses: stub_responses || false)
    end

    # Clouformation Resource
    # This is used to interact with the CloudFormation API
    # @see http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation/Resource.html
    # @note this uses a class variable for the client and the resource so they can share
    # the stubbed responses in the unit tests.
    def cfn
      @@resource ||= Aws::CloudFormation::Resource.new(client: cfn_client)
      @@resource
    end
  end
end
