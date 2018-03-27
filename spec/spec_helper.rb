#require "codeclimate-test-reporter"
#CodeClimate::TestReporter.start

require 'aws-sdk-cloudformation'
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'rspec/its'

RSpec.configure do |config|
  config.before(:each) do
    Aws.config[:stub_responses] = true
  end
end
