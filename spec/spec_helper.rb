require 'aws-sdk'
require_relative 'lib/cfncli/stack_utils'
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

RSpec.configure do |config|
  config.before(:each) do
    Aws.config[:stub_responses] = stubbed_response if respond_to? :stubbed_response
  end
end
