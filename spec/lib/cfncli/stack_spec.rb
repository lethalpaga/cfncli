require 'cfncli/stack'

describe CfnCli::Stack do
  subject(:stack) { CfnCli::Stack.new('test-stack') }

  before do
    Aws.config[:stub_responses] = stubbed_response
  end

  describe '#finished?' do
    subject { stack.finished? }

    context 'when in a finished state' do
      let(:state) { 'UPDATE_COMPLETE' }

      let(:stubbed_response) do
        {
          list_stacks: {
            stack_summaries: [
              {
                stack_id: 'test-stack-id',
                stack_name: 'test-stack',
                creation_time: Time.now,
                stack_status: 'UPDATE_COMPLETE',
              }
            ]
          }
        }
      end

      it { is_expected.to be true }
    end
  end
end
