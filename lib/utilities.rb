require 'yaml'
require 'yaml/store'
require 'digest'

module Ripple
  class Utilities
    @configs = {}
    @root    = File.dirname(File.dirname(File.expand_path __FILE__))
    @parent  = File.dirname(@root)

    class << self
      def get_config(config_file, default = get_default_config)
        unless @configs.has_key? config_file
          @configs[config_file] = default
          @configs[config_file].merge!(YAML.load_file(config_file)) if (File.exists? config_file)
        end

        @configs[config_file]
      end

      def get_default_config
        {
            backups:  3,
            composer: {
                vendor:  'clean',
                command: 'install',
                source:  'dist',
                flags:   '-o'
            },
            git:      {
                branch: 'master',
                remote: 'origin'
            }
        }
      end

      def get_project_config(project_name, default = get_ripple_config)
        get_config @parent + '/' + project_name + '/ripple.yml', default
      end

      def get_ripple_config
        get_config @root + '/ripple_config.yml'
      end

      def hash(to_hash)
        (Digest::SHA256.new << to_hash).to_s
      end

      def parent
        @parent
      end

      def save_ripple_config(config)
        store = YAML::Store.new @root + '/ripple_config.yml'
        store.transaction do
          config.each do |key, val|
            store[key] = val
          end
        end
      end

      def stop(message)
        puts message
        exit
      end
    end
  end
end