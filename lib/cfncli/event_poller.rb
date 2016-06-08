require 'colorize'
require 'cfncli/event'
require 'thread'

module CfnCli
  class EventPoller

    def initialize
      @mutex = Mutex.new
    end

    def event(event, prefix = nil)
      colorize Event.new(event), prefix
    end

    def colorize(event, prefix = nil)
      @mutex.synchronize do
        puts add_prefix(event.to_s, prefix).colorize(event.color)
      end
    end

    def add_prefix(message, prefix = nil)
      message = "#{prefix} - #{message}" unless prefix.nil?
      message
    end
  end
end
