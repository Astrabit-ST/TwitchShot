module Twitch
  # A small module for handling logging
  module Log
    # Enum for log levels
    module LogLevel
      FATAL = 0
      ERROR = 1
      WARN = 2
      INFO = 3
      DEBUG = 4

      Strings = {
        FATAL => "FATAL: ",
        ERROR => "ERROR: ",
        WARN => "WARN: ",
        INFO => "INFO: ",
        DEBUG => "DEBUG: ",
      }
    end

    # Colors for each log level
    module Color
      FATAL = :red
      ERROR = :red
      WARN = :yellow
      INFO = :yellow
      DEBUG = :magenta

      Enum = {
        LogLevel::FATAL => FATAL,
        LogLevel::ERROR => ERROR,
        LogLevel::WARN => WARN,
        LogLevel::INFO => INFO,
        LogLevel::DEBUG => DEBUG,
      }
    end

    module Types
      include LogLevel
    end

    # Logs a message to the console
    # Paints the message with the appropriate color
    #
    # @param message [String] The message to log
    # @param level [Integer] The log level of the message (preferably a constant from LogLevel)
    def self.log(message, type)
      const = const_get("LogLevel::#{Config["log_level"]}")
      if const >= type
        puts (LogLevel::Strings[type] + message)
      end
    end
  end
end
