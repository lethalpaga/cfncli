require 'cfncli/cloudformation'
require 'active_support/hash_with_indifferent_access'

describe CfnCli::CloudFormation do
  subject(:cfn) do
    cfn = CfnCli::CloudFormation.new
    cfn.retries = 1
    cfn.interval = 0
    cfn.stub_responses = true
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
    let(:client) {cfn.cfn.client}

    let(:create_stack_resp) do
      client.stub_data(:create_stack, stack_id: 'test-stack-id')
    end

    before do
      client.stub_responses(:create_stack, create_stack_resp)
      client.stub_responses(:describe_stacks, describe_stacks_resp)
    end

    context 'when successful' do
      let(:describe_stacks_resp) do
        client.stub_data(:describe_stacks, stacks: [{
          stack_id: 'test-stack-id',
          stack_name: 'test-stack',
          stack_status: 'CREATE_COMPLETE'
        }])
      end

      it { is_expected.to be true }
    end

    context 'when failed' do
      let(:describe_stacks_resp) do
        client.stub_data(:describe_stacks, stacks: [{
          stack_id: 'test-stack-id',
          stack_name: 'test-stack',
          stack_status: 'CREATE_FAILED'
        }])
      end

      it { is_expected.to be false }
    end
  end
end
