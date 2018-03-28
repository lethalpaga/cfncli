require 'cfncli/stack'
require 'active_support/hash_with_indifferent_access'

def describe_stacks_resp(status)
  client.stub_data(:describe_stacks, {
    stacks: [{
      stack_status: status
    }]
  })
end

describe CfnCli::Stack do
  subject(:stack) do
    stack = CfnCli::Stack.new('test-stack', config)
    stack.stub_responses = true
    stack
  end

  let(:client) {stack.cfn.client}
  let(:config) { CfnCli::Config::CfnClient.new(0, 1, false) }

  describe '#wait_for_completion' do
    subject { stack.wait_for_completion }

    before do
      expect(stack).to receive(:finished?).and_return finished
    end

    context 'when not timing out' do
      before do
        expect(stack).to receive(:succeeded?).and_return success
      end

      context 'when successful' do
        let(:finished) { true }
        let(:success) { true }

        it { is_expected.to be true }
      end

      context 'when failed' do
        let(:finished) { true }
        let(:success) { false }

        it { is_expected.to be false }
      end
    end

    context 'when timing out' do
      let(:finished) { false }
      let(:success) { true }

      it { is_expected.to be false }
    end
  end

  describe '#update' do
    subject { stack.update({}) }

    context 'when there is no update' do
      before do
        expect(client).to receive(:update_stack).and_raise(Aws::CloudFormation::Errors::ValidationError.new(nil, 'No updates are to be performed'))
      end

      context 'when fail_on_noop is true' do
        before do
          expect(stack).to receive(:fail_on_noop?).and_return true
        end

        it 'is expected to raise a ValidationError' do
          expect { subject }.to raise_error(Aws::CloudFormation::Errors::ValidationError)
        end
      end

      context 'when fail_on_noop is false' do
        before do
          expect(stack).to receive(:fail_on_noop?).and_return false
        end

        it 'is expected to be successful' do
          subject
        end
      end
    end

    context 'when throwing another ValidationError' do
      before do
        expect(client).to receive(:update_stack).and_raise(Aws::CloudFormation::Errors::ValidationError.new(nil, 'Random validation error'))
      end

      context 'when fail_on_noop is true' do
        before do
          expect(stack).to receive(:fail_on_noop?).and_return true
        end

        it 'is expected to raise a ValidationError' do
          expect { subject }.to raise_error(Aws::CloudFormation::Errors::ValidationError)
        end
      end

      context 'when fail_on_noop is false' do
        before do
          expect(stack).to receive(:fail_on_noop?).and_return false
        end

        it 'is expected to be raise a ValidationError' do
          expect { subject }.to raise_error(Aws::CloudFormation::Errors::ValidationError)
        end
      end
    end
  end

  describe 'Stack state detection' do
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


  describe '#events' do
    let(:event) do
      {
        event_id: '2',
        stack_id: stack.stack_id,
        stack_name: stack.stack_name,
        timestamp: Time.now
      }
    end

    before do
      client.stub_responses :describe_stack_events, {
        stack_events: [
          event
        ]
      }
    end
    it 'returns the stack events' do
      expect(stack.events.first.event_id).to eq(event[:event_id])
    end
  end

  describe '#list_events' do
    let(:streamer) { double('CfnCli::EventStreamer') }
    let(:poller) { double('CfnCli::EventPoller') }
    let(:test_event) { double('AWS::CloudFormation::Event') }
    let(:cli_event) { double('CfnCli::Event') }
    before do
      allow(streamer).to receive(:each_event) do |&block|
        block.call(test_event)
      end
      allow(poller).to receive(:event).with test_event, nil
      allow(CfnCli::Event).to receive(:new).with(test_event).and_return cli_event
      allow(cli_event).to receive(:child_stack_create_event?).and_return false
      allow(Thread).to receive(:new) do |&block|
        block.call
      end
    end

    it 'passes a block to each_event for streaming' do
      expect(streamer).to receive(:each_event)
      subject.list_events poller, streamer
    end

    context 'each_event block' do
      let(:resource_id) { 'FAKE_ID' }
      let(:logical_id) { 'TEST_ID' }

      context 'when list_nested_events is true' do
        it 'detects and tracks child stacks if event is a child stack creation' do
          expect(test_event).to receive(:physical_resource_id).and_return resource_id
          expect(test_event).to receive(:logical_resource_id).and_return logical_id
          expect(cli_event).to receive(:child_stack_create_event?).and_return true
          expect(subject).to receive(:track_child_stack).with resource_id, logical_id, poller
          subject.list_events poller, streamer
        end
      end

      context 'when list_nested_events is false' do
        it 'does not detect and track child stacks if event is a child stack creation' do
          expect(test_event).not_to receive(:physical_resource_id)
          expect(test_event).not_to receive(:logical_resource_id)
          expect(cli_event).not_to receive(:child_stack_create_event?)
          expect(subject).not_to receive(:track_child_stack)
          subject.list_events poller, streamer, nil, nil, false
        end
      end

      it 'sends the event to the poller' do
        expect(poller).to receive(:event).with test_event, nil
        subject.list_events poller, streamer
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
