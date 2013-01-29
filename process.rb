require 'net/http'

def ripple_process(directory, opts)
  	Dir.chdir(directory)
  	
  	output = `git reset --hard HEAD`
  	
  	output = `git pull origin master`
  	
  	composer = "#{directory}/composer.phar"
  	composer_json = "#{directory}/composer.json"
  	
  	if File.exists? composer_json
  	  unless File.exists? composer
  	    c = Net::HTTP.get_response(URI.parse('http://getcomposer.org/installer')).body
  	    
  	    f = File.new(composer, 'w')
  	    f.write(c)
  	    f.close
  	  end
  	end
  	
  	gemfile = "#{directory}/Gemfile"
  	
  	if File.exists? gemfile
  	  # Do some builder stuff
  	end
  	
  	output = `php #{composer} self-update`
  	output = `php #{composer} install --prefer-dist -o`
  	
  	if opts.has_key? 'post_exec'
  	  for opts['post_exec'].each do |e|
  	    `e`
  	  end
  	end
end