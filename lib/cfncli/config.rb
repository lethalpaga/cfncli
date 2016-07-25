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
      attr_accessor :aws_retry_limit
      attr_accessor :aws_retry_backoff

      def initialize(interval = 10, retries = 30, fail_on_noop = false, aws_retry_limit = 5, aws_retry_backoff = nil)
        @interval = interval
        @retries = retries
        @fail_on_noop = fail_on_noop
        @aws_retry_limit = aws_retry_limit
        @aws_retry_backoff = aws_retry_backoff
      end
    end
  end
end
