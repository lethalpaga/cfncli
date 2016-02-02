require "cfncli/version"

require 'thor'

module Cfncli
  class Cli < Thor
    def create
      puts "Creating stack"
    end
  end
end
