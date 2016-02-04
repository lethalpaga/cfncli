module CfnCli
  module Config
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
  end
end
