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
end
