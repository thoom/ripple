require 'yaml'

module Ripple
  class Utilities
    @configs = {}

    def self.get_config(config_file, default = self.get_default)
      unless @configs.has_key? config_file
        @configs[config_file] = default
        @configs[config_file].merge!(YAML.load_file(config_file)) if (File.exists? config_file)
      end

      @configs[config_file]
    end


    def self.get_default
      {backups: 3}
    end

    def self.stop(message)
      puts message
      exit
    end
  end
end