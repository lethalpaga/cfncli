require 'yaml'

module CfnCli
  module Config
    def self.load_from_file(filename)
      content = YAML::load_file(filename)
      Parameters.new(content)
    rescue Errno::ENOENT
      nil
    end
  
    class CfnClient
      attr_accessor :interval
      attr_accessor :retries
      attr_accessor :fail_on_noop
      
      def initialize(interval = 10, retries = 30, fail_on_noop = false)
        @interval = interval
        @retries = retries
        @fail_on_noop = fail_on_noop
      end
    end
    
    class Parameters
      def initialize(content)
        @content = content
      end
      
      # Converts parameters to command-line arguments
      def to_args(content = nil)
        content ||= to_a
        content.join(' ')
      end
      
      # Get an array of parameters
      def to_a
        from_hash(@content) if @content.is_a? Hash       
      end
      
      # Format parameters for thor
      # @param given_args [Array] Optional array of existing arguments
      def to_thor(given_args = nil)
        args = []

        if given_args
          given_args = given_args.dup
          args << given_args.shift
        end
        args += to_a
        args += given_args if given_args
        
        args
      end
      
      protected
      
      def from_hash(content)
        args = []
        content.each_pair do |key, value|
          case value
          when Hash
            value = parse_hash(value)
          when Array
            value = parse_array(value)
          end
          
          args += ["--#{key}", value]
        end
        
        args
      end
      
      def parse_hash(content)
        args = []
        content.each_pair do |key, value|
          args += ["#{key}:#{value}"]
        end
        
        args
      end
      
      def parse_array(value)
        "[#{value.join(',')}]"
      end
    end
  end
end
