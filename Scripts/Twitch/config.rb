require "json"

module Twitch
  # A small module for handling config
  module Config
    VERSION = "1.0.0".freeze

    # Loads the config file
    def self.load_config
      @config = JSON.load_file("twitch_config.json") rescue {}
    end

    # Returns the config value for the given key
    #
    # @param key [String] The key to get the value for
    def self.[](key)
      raise "Config key #{key} not found" unless @config.key?(key)
      @config[key]
    end
  end
end
