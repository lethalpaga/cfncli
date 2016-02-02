require "cfncli/version"

require 'thor'

module CfnCli
  class Cli < Thor
    def create
      puts "Creating stack"
    end
  end
end
