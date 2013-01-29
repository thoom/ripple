require 'net/http'

def ripple_process(directory, opts)
  Dir.chdir(directory)

  output   = `git reset --hard HEAD`
  output   = `git pull origin master`

  # For PHP projects using composer
  composer = "#{directory}/composer.phar"
  if File.exists? "#{directory}/composer.json"
    unless File.exists? composer
      c = Net::HTTP.get_response(URI.parse('http://getcomposer.org/installer')).body

      f = File.new(composer, 'w')
      f.write(c)
      f.close
    end
    output = `php #{ composer } self-update`
    output = `php #{ composer } install --prefer-dist -o`
  end

  # For Ruby projects using bundler
  gemfile = "#{directory}/Gemfile"
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
end