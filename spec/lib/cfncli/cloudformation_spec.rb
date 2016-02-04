require 'cfncli/cloudformation'
require 'active_support/hash_with_indifferent_access'

describe CfnCli::CloudFormation do
  subject(:cfn) do
    cfn = CfnCli::CloudFormation.new
    cfn.stub_responses = true
    cfn
  end

  describe '#create_or_update_stack' do
    subject { cfn.create_or_update_stack({}) }

    let(:stack) { double CfnCli::Stack }

    before do
      expect(cfn).to receive(:create_stack_obj).and_return(stack)
      expect(stack).to receive(:stack_name).and_return(exists)
      allow(stack).to receive(:exists?).and_return(exists)
    end

    context 'when the stack does not exist' do
      let(:exists) { false }
      it 'is expected to call stack.create' do
        expect(stack).to receive(:create).with({})
        subject
      end
    end

    context 'when the stack exists' do
      let(:exists) { true }
      it 'is expected to call stack.update' do
        expect(stack).to receive(:update).with({})
        subject
      end
    end
  end

=begin
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
      expect(cfn.cfn).to receive(:wait_until_exists).and_return(true)
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
=end
end
