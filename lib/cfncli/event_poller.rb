require 'colorize'
require 'cfncli/event'

module CfnCli
  class EventPoller
    def initialize
    end

    def event(event)
      colorize Event.new(event)
    end

    def colorize(event)
      puts event.to_s.colorize(event.color)
    end
  end
end
