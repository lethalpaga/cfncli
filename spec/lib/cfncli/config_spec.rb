require 'cfncli/config'

describe CfnCli::Config::Parameters do
  subject(:param) { described_class.new(config) }
  
  let(:simple_config) do
    {
      key1: 0,
      key2: 'value2',
      key3: true
    }
 end

  let(:hash_config) do
    {
      key1: {
        subkey1: 0,
        subkey2: 'subvalue2'
      }
    }
  end
  
  let(:array_config) do
    { key1:  [0, 1, 'test'] }
  end
    
  describe '#to_args' do
  
    subject { param.to_args }

    context 'when given a simple hash' do
        let(:config) { simple_config }        
        it { is_expected.to eq '--key1 0 --key2 value2 --key3 true' }
    end
    
    context 'when given a value with a hash' do
      let(:config) { hash_config }
      it { is_expected.to eq '--key1 subkey1:0 subkey2:subvalue2' }
    end
    
    context 'when given a value with an array' do
      let(:config) { array_config }
      it { is_expected.to eq '--key1 [0,1,test]' }
    end
  end
  
  describe '#to_thor' do
    subject { param.to_thor(args) }
    
    context 'when not given arguments' do
      let(:config) { simple_config }
      let(:args) { nil }
      
      it { is_expected.to eq ['--key1', 0, '--key2', 'value2', '--key3', true] }
    end

    context 'when given a command' do
      let(:config) { simple_config }
      let(:args) { ['command'] }
      
      it { is_expected.to eq ['command', '--key1', 0, '--key2', 'value2', '--key3', true] }
    end
    
    context 'when given a command and new arguments' do
      let(:config) { simple_config }
      let(:args) { ['command', '--newarg', true] }
      
      it { is_expected.to eq ['command', '--key1', 0, '--key2', 'value2', '--key3', true, '--newarg', true] }
    end

    context 'when given a command and overriding arguments' do
      let(:config) { simple_config }
      let(:args) { ['command', '--key3', false] }
      
      it { is_expected.to eq  ['command', '--key1', 0, '--key2', 'value2', '--key3', true, '--key3', false] }
    end
  end
end