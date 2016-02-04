require 'aws-sdk'
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'rspec/its'

RSpec.configure do |config|
  config.before(:each) do
    Aws.config[:stub_responses] = true
  end
end
