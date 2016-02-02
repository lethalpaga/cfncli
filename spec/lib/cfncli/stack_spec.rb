require 'cfncli/stack'

include CfnCli::StackUtils

describe CfnCli::Stack do
  subject(:stack) { CfnCli::Stack.new('test-stack') }

  describe '#finished?' do
    subject { stack.finished? }

    context 'when in a finished state' do
      let(:stubbed_response) { stub_stack(CfnCli::StackUtils.updated_stack) }

      it { is_expected.to be true }
    end

    context 'when in a transition state' do
      let(:stubbed_response) { stub_stack(update_in_progress_stack) }

      it { is_expected.to be false }
    end
  end

  describe '#succeeded' do
    subject { stack.succeeded? }

    context 'when in a successful state' do
      let(:stubbed_response) { stub_stack(updated_stack) }

      it { is_expected.to be true }
    end
    
    context 'when in a transition state' do
      let(:stubbed_response) { stub_stack(update_in_progress_stack) }

      it { is_expected.to be false }
    end
    
    context 'when in a failed state' do
      let(:stubbed_response) { stub_stack(update_failed_stack) }

      it { is_expected.to be false }
    end
  end

  describe '#in_progress' do
    subject { stack.in_progress? }

    context 'when in a successful state' do
      let(:stubbed_response) { stub_stack(updated_stack) }

      it { is_expected.to be false }
    end
    
    context 'when in a transition state' do
      let(:stubbed_response) { stub_stack(update_in_progress_stack) }

      it { is_expected.to be true }
    end
    
    context 'when in a failed state' do
      let(:stubbed_response) { stub_stack(update_failed_stack) }

      it { is_expected.to be false }
    end
  end

  describe '#failed' do
    subject { stack.failed? }

    context 'when in a successful state' do
      let(:stubbed_response) { stub_stack(updated_stack) }

      it { is_expected.to be false }
    end
    
    context 'when in a transition state' do
      let(:stubbed_response) { stub_stack(update_in_progress_stack) }

      it { is_expected.to be false }
    end
    
    context 'when in a failed state' do
      let(:stubbed_response) { stub_stack(update_failed_stack) }

      it { is_expected.to be true }
    end
  end
end
