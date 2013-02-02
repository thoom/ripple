require 'sinatra'
require_relative 'utilities'

root = File.dirname(File.dirname(__FILE__))
set parent: File.dirname(root)
set ripple: Ripple::Utilities.get_config("#{ root }/ripple_config.yml")

# Basic authentication
use Rack::Auth::Basic, 'Ripple Protected Area' do |username, password|
  settings.ripple && username == settings.ripple['username'] && password == settings.ripple['password']
end

configure :production do
  disable :raise_errors
end

get '/' do
  'Ripple deployment server'
end

post '/:project/:secret' do |project, secret|
  halt 400, 'Missing payload' unless params[:payload]

  project_dir = "#{ settings.parent }/#{ project }"
  vsecret     = (settings.ripple.has_key?('secret') && settings.ripple['secret'].has_key?(project)) ? settings.ripple['secret'][project] : nil

  halt 400, 'Invalid security secret' unless secret == vsecret
  halt 400, 'Invalid project name' unless File.directory? "#{ project_dir }/.git"

  project_ripple = "#{ project_dir }/ripple.yml"

  opts = (File.exists? project_ripple) ? Ripple::Utilities.get_config(project_ripple) : {}
  opts = {} unless opts

  File.write("#{ project_dir }/ripple_payload.json", params[:payload])

  require_relative 'git'
  r = Ripple::Git.new(project_dir, opts)
  r.process

  'OK'
end

not_found do
  'Page not found!'
end

error do
  "Sorry, an error occurred:\n" + env['sinatra.error'].name
end