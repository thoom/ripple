require 'sinatra'
require_relative 'utilities'

set parent: Ripple::Utilities.parent
set ripple: Ripple::Utilities.get_ripple_config

# Basic authentication
use Rack::Auth::Basic, 'Ripple Protected Area' do |username, password|
  settings.ripple && username == settings.ripple[:username] && Ripple::Utilities.hash(password) == settings.ripple[:password]
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
  vsecret     = (settings.ripple.has_key?(:secret) && settings.ripple[:secret].has_key?(project)) ? settings.ripple[:secret][project] : nil

  halt 400, 'Invalid security secret' unless Ripple::Utilities.hash(secret) == vsecret
  halt 400, 'Invalid project name' unless File.directory? "#{ project_dir }/.git"

  require_relative 'git'
  r = Ripple::Git.new(project_dir, Ripple::Utilities.get_project_config(project))
  r.process

  File.write("#{ project_dir }/payload.json", params[:payload])
  'OK'
end

not_found do
  'Page not found!'
end

error do
  "Sorry, an error occurred:\n" + env['sinatra.error'].name
end