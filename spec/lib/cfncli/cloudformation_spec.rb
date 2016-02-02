require 'cfncli/cloudformation'
require 'active_support/hash_with_indifferent_access'

describe CfnCli::CloudFormation do
  subject(:cfn) do
    cfn = CfnCli::CloudFormation.new
    cfn.retries = 1
    cfn.interval = 0
    cfn
  end

  let(:stack_params) do
    ActiveSupport::HashWithIndifferentAccess.new({
      stack_name: 'test-stack',
      template_body: '{}'
    })
  end

  describe '#create_stack' do
    subject { cfn.create_stack(stack_params) }

    before do
      cfn.cfn.client.stub_responses(true)
    end

    context 'when successful' do
      let(:stubbed_response) { stub_stack(updated_stack) }

      it { is_expected.to be true }
    end

    context 'when failed' do
      let(:stubbed_response) { stub_stack(update_failed_stack) }

      it { is_expected.to be false }
    end
  end
end
