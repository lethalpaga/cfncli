require 'cfncli/event_streamer'

describe CfnCli::EventStreamer do
  subject(:streamer) { CfnCli::EventStreamer.new(nil) }

  describe '#seen?' do
    subject { streamer.send(:seen?, event) }
    let(:event) { double CfnCli::Event }
    let(:event_id) { 'test-id' }

    before do
      allow(event).to receive(:id).and_return event_id
    end
 
    context 'when receiving a new event' do
      before do
        allow(streamer).to receive(:seen_events).and_return []
      end

      it { is_expected.to be false }
    end
 
    context 'when receiving an existing event' do
      before do
        allow(streamer).to receive(:seen_events).and_return [event_id]
      end

      it { is_expected.to be true }
    end
  end
end
