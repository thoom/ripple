require 'yaml'

def get_config(config_file)
  return false unless File.exists? config_file

  YAML.load_file config_file
end

def stop(message)
  puts message
  exit
end