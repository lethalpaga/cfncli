require 'cfncli/event'

describe CfnCli::Event do
  subject(:event) { CfnCli::Event.new(nil) }

  describe '#color' do
    subject { event.color }

    context 'when the event is successful' do
      before do
        expect(event).to receive(:succeeded?).and_return true
      end

      it { is_expected.to be :green }
    end

    context 'when the event is in progress' do
      before do
        expect(event).to receive(:succeeded?).and_return false
        expect(event).to receive(:in_progress?).and_return true
      end

      it { is_expected.to be :yellow }
    end

    context 'when the event is failed' do
      before do
        expect(event).to receive(:succeeded?).and_return false
        expect(event).to receive(:in_progress?).and_return false
        expect(event).to receive(:failed?).and_return true
      end

      it { is_expected.to be :red }
    end
  end

  describe '#child_stack_create_event?' do
    subject { event.child_stack_create_event? }
    before do
      event.instance_variable_set :@event, event_obj
    end
    context 'when event is a child stack creation event' do
      let(:event_obj) { double('AWS::CloudFormation::Event') }
      let(:resource_type) { 'AWS::CloudFormation::Stack' }
      let(:status_reason) { 'Resource creation Initiated' }
      before do
        expect(event).to receive(:in_progress?).and_return true
        expect(event_obj).to receive(:resource_type).and_return resource_type
        expect(event_obj).to receive(:resource_status_reason).and_return status_reason
      end

      it { is_expected.to be true }
    end

    context 'when event is not a child stack creation event' do
      let(:event_obj) { double('AWS::CloudFormation::Event') }
      context 'when event is not in progress' do
        before do
          expect(event).to receive(:in_progress?).and_return false
        end

        it { is_expected.to be false }
      end

      context 'when resource type is not a stack' do
        let(:event_obj) { double('AWS::CloudFormation::Event') }
        let(:resource_type) { 'AWS::AutoScaling::AutoScalingGroup' }
        before do
          expect(event).to receive(:in_progress?).and_return true
          expect(event_obj).to receive(:resource_type).and_return resource_type
        end

        it { is_expected.to be false }
      end

      context 'when status reason is not creation initiated' do
        let(:event_obj) { double('AWS::CloudFormation::Event') }
        let(:resource_type) { 'AWS::CloudFormation::Stack' }
        let(:status_reason) { 'Received SUCCESS signal' }
        before do
          expect(event).to receive(:in_progress?).and_return true
          expect(event_obj).to receive(:resource_type).and_return resource_type
          expect(event_obj).to receive(:resource_status_reason).and_return status_reason
        end

        it { is_expected.to be false }
      end
    end
  end
end
