require 'cfncli/cli'

describe CfnCli::Cli do
  subject(:cli) { CfnCli::Cli.new }

  describe '#check_exclusivity' do

    subject do
      cli.check_exclusivity(options, exclusives)
    end

    let(:options) do
      ['option1', 'option2']
    end

    context 'when given mutually exclusive options' do
      let(:exclusives) do
        ['option1', 'option2']
      end

      it 'is expected to raise a Thor::Error exception' do
        expect { subject }.to raise_error Thor::Error
      end
    end

    context 'when not given mutually exclusive options' do
      let(:exclusives) do
        ['option1', 'option3']
      end

      it 'is expected to not raise an error' do
        expect { subject }.not_to raise_error
      end
    end
  end

  describe '#file_or_content' do
    subject { cli.file_or_content(input) }

    context 'when given a string' do
      let(:input) { 'test string' }

      it { is_expected.to eq 'test string' }
    end

    context 'when given a filename' do
      let(:input) { '@path/to/file' }

      before do
        expect(File).to receive(:read).with('path/to/file').and_return('file content')
      end

      it { is_expected.to eq 'file content' }
    end
  end

  describe '#process_stack_parameters' do
    subject { cli.process_stack_parameters(params) }

    let(:params) do
      [
        {
          'ParameterKey' => :opt1,
          'ParameterValue' => 'val1'
        },
        {
          'ParameterKey' => :opt2,
          'ParameterValue' => 'val2'
        }
      ]
    end

    let(:expected_result) do
      [
        {
          parameter_key: :opt1,
          parameter_value: 'val1'
        },
        {
          parameter_key: :opt2,
          parameter_value: 'val2'
        }
      ]
    end

    it { is_expected.to eq expected_result }
  end
end
