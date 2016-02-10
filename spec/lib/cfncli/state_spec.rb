require 'cfncli/states'

describe CfnCli::CfnStates do
  subject(:state) do
    class TestState
      include CfnCli::CfnStates
    end

    TestState.new
  end

  describe 'State detection' do
    before do
      allow(state).to receive(:status).and_return(stubbed_response)
    end

    let(:update_complete) { 'UPDATE_COMPLETE' }
    let(:update_in_progress) { 'UPDATE_IN_PROGRESS' }
    let(:update_failed) { 'UPDATE_FAILED' }

    describe '#finished?' do
      subject { state.finished? }

      context 'when in a finished state' do
        let(:stubbed_response) { update_complete }
         
        it { is_expected.to be true }
      end

      context 'when in a transition state' do
        let(:stubbed_response) { update_in_progress }

        it { is_expected.to be false }
      end
    end

    describe '#succeeded' do
      subject { state.succeeded? }

      context 'when in a successful state' do
        let(:stubbed_response) { update_complete }

        it { is_expected.to be true }
      end
      
      context 'when in a transition state' do
        let(:stubbed_response) { update_in_progress }

        it { is_expected.to be false }
      end
      
      context 'when in a failed state' do
        let(:stubbed_response) { update_failed }

        it { is_expected.to be false }
      end
    end

    describe '#in_progress' do
      subject { state.in_progress? }

      context 'when in a successful state' do
        let(:stubbed_response) { update_complete}

        it { is_expected.to be false }
      end
      
      context 'when in a transition state' do
        let(:stubbed_response) { update_in_progress}

        it { is_expected.to be true }
      end
      
      context 'when in a failed state' do
        let(:stubbed_response) { update_failed }

        it { is_expected.to be false }
      end
    end

    describe '#failed' do
      subject { state.failed? }

      context 'when in a successful state' do
        let(:stubbed_response) { update_complete }

        it { is_expected.to be false }
      end
      
      context 'when in a transition state' do
        let(:stubbed_response) { update_in_progress }

        it { is_expected.to be false }
      end
      
      context 'when in a failed state' do
        let(:stubbed_response) { update_failed }

        it { is_expected.to be true }
      end
    end
  end

  describe '#transitive_states' do
     subject { state.transitive_states }

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
     subject { state.finished_states }

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
     subject { state.success_states }

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
     subject { state.failed_states }
     
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
