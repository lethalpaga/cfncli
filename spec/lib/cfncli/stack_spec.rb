require 'cfncli/stack'

def describe_stacks_resp(status)
  client.stub_data(:describe_stacks, {
    stacks: [{
      stack_status: status
    }]
  })
end

describe CfnCli::Stack do
  subject(:stack) do
    stack = CfnCli::Stack.new('test-stack')
    stack.stub_responses = true
    stack
  end

  describe 'Stack state detection' do
    let(:client) {stack.cfn.client}

    let(:updated_stack) { describe_stacks_resp('UPDATE_COMPLETE') }
    let(:update_failed_stack) { describe_stacks_resp('UPDATE_FAILED') }
    let(:update_in_progress_stack) { describe_stacks_resp('UPDATE_IN_PROGRESS') }

    before do
      client.stub_responses :describe_stacks, stubbed_response
    end

    describe '#finished?' do
      subject { stack.finished? }

      context 'when in a finished state' do
        let(:stubbed_response) { updated_stack }

        it { is_expected.to be true }
      end

      context 'when in a transition state' do
        let(:stubbed_response) { update_in_progress_stack }

        it { is_expected.to be false }
      end
    end

    describe '#succeeded' do
      subject { stack.succeeded? }

      context 'when in a successful state' do
        let(:stubbed_response) { updated_stack }

        it { is_expected.to be true }
      end
      
      context 'when in a transition state' do
        let(:stubbed_response) { update_in_progress_stack }

        it { is_expected.to be false }
      end
      
      context 'when in a failed state' do
        let(:stubbed_response) { update_failed_stack }

        it { is_expected.to be false }
      end
    end

    describe '#in_progress' do
      subject { stack.in_progress? }

      context 'when in a successful state' do
        let(:stubbed_response) { updated_stack }

        it { is_expected.to be false }
      end
      
      context 'when in a transition state' do
        let(:stubbed_response) { update_in_progress_stack }

        it { is_expected.to be true }
      end
      
      context 'when in a failed state' do
        let(:stubbed_response) { update_failed_stack }

        it { is_expected.to be false }
      end
    end

    describe '#failed' do
      subject { stack.failed? }

      context 'when in a successful state' do
        let(:stubbed_response) { updated_stack }

        it { is_expected.to be false }
      end
      
      context 'when in a transition state' do
        let(:stubbed_response) { update_in_progress_stack }

        it { is_expected.to be false }
      end
      
      context 'when in a failed state' do
        let(:stubbed_response) { update_failed_stack }

        it { is_expected.to be true }
      end
    end
  end

  describe '#transitive_states' do
     subject { stack.transitive_states }

     it { is_expected.to include 'CREATE_IN_PROGRESS' }
     it { is_expected.to include 'ROLLBACK_IN_PROGRESS' }
     it { is_expected.to include 'DELETE_IN_PROGRESS' }
     it { is_expected.to include 'CREATE_IN_PROGRESS' }
     it { is_expected.to include 'UPDATE_COMPLETE_CLEANUP_IN_PROGRESS' }
     it { is_expected.to include 'UPDATE_IN_PROGRESS' }
     it { is_expected.to include 'UPDATE_ROLLBACK_IN_PROGRESS' }
     it { is_expected.to include 'UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS' }

     it { is_expected.not_to include 'CREATE_FAILED' }
     it { is_expected.not_to include 'CREATE_COMPLETE' }
     it { is_expected.not_to include 'ROLLBACK_FAILED' }
     it { is_expected.not_to include 'ROLLBACK_COMPLETE' }
     it { is_expected.not_to include 'UPDATE_COMPLETE' }
     it { is_expected.not_to include 'UPDATE_ROLLBACK_FAILED' }
     it { is_expected.not_to include 'UPDATE_ROLLBACK_COMPLETE' }
     it { is_expected.not_to include 'DELETE_COMPLETE' }
  end

  describe '#finished_states' do
     subject { stack.finished_states }

     it { is_expected.to include 'CREATE_COMPLETE' }
     it { is_expected.to include 'UPDATE_COMPLETE' }
     it { is_expected.to include 'DELETE_COMPLETE' }
     it { is_expected.to include 'CREATE_FAILED' }
     it { is_expected.to include 'ROLLBACK_FAILED' }
     it { is_expected.to include 'ROLLBACK_COMPLETE' }
     it { is_expected.to include 'UPDATE_ROLLBACK_FAILED' }
     it { is_expected.to include 'UPDATE_ROLLBACK_COMPLETE' }

     it { is_expected.not_to include 'CREATE_IN_PROGRESS' }
     it { is_expected.not_to include 'ROLLBACK_IN_PROGRESS' }
     it { is_expected.not_to include 'DELETE_IN_PROGRESS' }
     it { is_expected.not_to include 'CREATE_IN_PROGRESS' }
     it { is_expected.not_to include 'UPDATE_COMPLETE_CLEANUP_IN_PROGRESS' }
     it { is_expected.not_to include 'UPDATE_IN_PROGRESS' }
     it { is_expected.not_to include 'UPDATE_ROLLBACK_IN_PROGRESS' }
     it { is_expected.not_to include 'UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS' }
  end

  describe '#success_states' do
     subject { stack.success_states }

     it { is_expected.to include 'CREATE_COMPLETE' }
     it { is_expected.to include 'UPDATE_COMPLETE' }
     it { is_expected.to include 'DELETE_COMPLETE' }

     it { is_expected.not_to include 'CREATE_IN_PROGRESS' }
     it { is_expected.not_to include 'ROLLBACK_IN_PROGRESS' }
     it { is_expected.not_to include 'DELETE_IN_PROGRESS' }
     it { is_expected.not_to include 'CREATE_IN_PROGRESS' }
     it { is_expected.not_to include 'UPDATE_COMPLETE_CLEANUP_IN_PROGRESS' }
     it { is_expected.not_to include 'UPDATE_IN_PROGRESS' }
     it { is_expected.not_to include 'UPDATE_ROLLBACK_IN_PROGRESS' }
     it { is_expected.not_to include 'UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS' }
     it { is_expected.not_to include 'CREATE_FAILED' }
     it { is_expected.not_to include 'ROLLBACK_FAILED' }
     it { is_expected.not_to include 'ROLLBACK_COMPLETE' }
     it { is_expected.not_to include 'UPDATE_ROLLBACK_FAILED' }
     it { is_expected.not_to include 'UPDATE_ROLLBACK_COMPLETE' }
  end

  describe '#failed_states' do
     subject { stack.failed_states }
     
     it { is_expected.to include 'ROLLBACK_FAILED' }
     it { is_expected.to include 'ROLLBACK_COMPLETE' }
     it { is_expected.to include 'UPDATE_ROLLBACK_FAILED' }
     it { is_expected.to include 'UPDATE_ROLLBACK_COMPLETE' }
     it { is_expected.to include 'CREATE_FAILED' }

     it { is_expected.not_to include 'CREATE_COMPLETE' }
     it { is_expected.not_to include 'UPDATE_COMPLETE' }
     it { is_expected.not_to include 'DELETE_COMPLETE' }
     it { is_expected.not_to include 'CREATE_IN_PROGRESS' }
     it { is_expected.not_to include 'ROLLBACK_IN_PROGRESS' }
     it { is_expected.not_to include 'DELETE_IN_PROGRESS' }
     it { is_expected.not_to include 'CREATE_IN_PROGRESS' }
     it { is_expected.not_to include 'UPDATE_COMPLETE_CLEANUP_IN_PROGRESS' }
     it { is_expected.not_to include 'UPDATE_IN_PROGRESS' }
     it { is_expected.not_to include 'UPDATE_ROLLBACK_IN_PROGRESS' }
     it { is_expected.not_to include 'UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS' }
  end
end
