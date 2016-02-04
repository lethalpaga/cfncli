require 'logger'

module CfnCli
  # Logger Mixin
  module Loggable
    # Gets the logger object
    #
    # By default it logs to STDOUT with the date-time format +%Y-%m-%d %H:%M:%S +
    #
    # @return [Logger]
    def logger
      if @logger.nil?
        @logger = Logger.new(STDOUT)
        @logger.level = ENV['CFNCLI_LOG_LEVEL'].to_i || Logger::INFO
        @logger.formatter = proc do |severity, datetime, progname, msg|
          severity = severity.ljust(7)
          progname = "#{progname}: " if progname
          "#{datetime} [ #{severity} ] #{progname}#{msg}\n"
        end
      end
      @logger
    end

    # Sets the logger object
    # @param obj [Logger]
    def logger=(obj)
      @logger = obj
    end

    # Gets the current log level as a symbol
    # @return [Symbol]
    def log_level
      level_map = {
        Logger::DEBUG => :debug,
        Logger::INFO => :info,
        Logger::WARN => :warn,
        Logger::ERROR => :error,
        Logger::FATAL => :fatal,
        Logger::UNKNOWN => :unknown
      }
      level_map[logger.level]
    end

    # Sets the current log level
    def log_level=(level)
      if level.is_a?(Fixnum)
        logger.level = level
      else
        logger.level = Logger.const_get(level.to_s.upcase)
      end
    end
  end
end
