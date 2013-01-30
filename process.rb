require 'net/http'
require 'fileutils'

def ripple_process(directory, opts)
  temp_dir = directory + '_temp'
  back_dir = directory + '_backup'
  if Dir.exists? temp_dir
    Dir.delete temp_dir
  end

  if Dir.exists? back_dir
    Dir.delete back_dir
  end

  FileUtils.copy directory, temp_dir
  Dir.chdir temp_dir

  output   = `git reset --hard HEAD`
  output   = `git pull origin master`

  # For PHP projects using composer
  composer = 'composer.phar'
  if File.exists? 'composer.json'
    unless File.exists? composer
      c = Net::HTTP.get_response(URI.parse('http://getcomposer.org/installer')).body

      f = File.new(composer, 'w')
      f.write(c)
      f.close
    end

    if Dir.exists? '/vendor'
      Dir.delete '/vendor'
    end

    output = `php #{ composer } self-update`
    output = `php #{ composer } install --prefer-dist -o`
  end

  # For Ruby projects using bundler
  gemfile = 'Gemfile'
  if File.exists? gemfile
    # Do some bundler stuff
    output = `bundle install`
  end

  # Post executable files
  if opts.has_key? 'post_exec'
    opts['post_exec'].each do |e|
      `#{ e }`
    end
  end

  # Move the current directory to the backup directory and move the temp directory to the current directory's place
  FileUtils.move directory, back_dir
  FileUtils.move temp_dir, directory

  if opts.has_key? 'final_exec'
    Dir.chdir directory
    opts['post_move'].each do |e|
      `#{ e }`
    end
  end
end