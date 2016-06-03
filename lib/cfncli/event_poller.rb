require 'colorize'
require 'cfncli/event'

module CfnCli
  class EventPoller
    attr_reader :message_prefix
    def initialize(message_prefix = nil)
      @message_prefix = message_prefix
    end

    def event(event)
      colorize Event.new(event)
    end

    def colorize(event)
      puts add_prefix(event.to_s).colorize(event.color)
    end

    def add_prefix(message)
      message = "#{message_prefix} - #{message}" unless message_prefix.nil?
      message
    end
  end
end
