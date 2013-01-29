require 'digest/sha1'
require 'webrick'
require 'yaml'

root   = File.dirname(__FILE__)
parent = File.dirname(root)

config_file = "#{ root }/ripple_config.yml"
unless File.exists? config_file
  res.status = 500
  res.body   = 'Configuration file missing'
  exit
end

config = YAML.load_file config_file
port   = (config && config.has_key?('port')) ? config['port'] : 8000
server = WEBrick::HTTPServer.new :Port => port, :DocumentRoot => root

server.mount_proc '/' do |req, res|
  project, hash = req.path[1..-1].split('/')

  if project == nil && hash == nil
    res.body = 'Ripple deployment server'
    exit
  end

  if project == nil || project.empty?
    res.status = 400
    res.body   = 'Missing project to pull'
    exit
  end

  if hash == nil || hash.empty?
    res.status = 400
    res.body   = 'Missing security hash'
  end

  project_dir = "#{parent}/#{project}"
  vhash       = (config && config.has_key?('hash') && config['hash'].has_key?(project)) ? config['hash'][project] : Digest::SHA1.hexdigest(project_dir)

  unless hash == vhash
    res.status = 400
    res.body   = 'Invalid security hash'
    exit
  end

  unless File.directory? "#{project_dir}/.git"
    res.status = 400
    res.body   = 'Invalid project name'
    exit
  end

  load parent + '/process.rb'
  ripple_process(project_dir, {})
end

trap 'INT' do
  server.shutdown
end

server.start