require 'yaml'

module Ripple
  class Utilities
    @configs = {}

    def self.get_config(config_file)
      unless @configs.has_key? config_file
        @configs[config_file] = (File.exists? config_file) ? YAML.load_file(config_file) : false
      end

      @configs[config_file]
    end

    def self.stop(message)
      puts message
      exit
    end
  end
end