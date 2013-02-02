require 'net/http'
require 'fileutils'
require 'tempfile'

module Ripple
  class Git
    @directory, @opts, @log, @console = nil

    def initialize(directory, opts)
      @directory = directory
      @opts      = opts
      @log       = Tempfile.new('ripple-server')
      @console   = (opts.has_key?(:console) && opts[:console] == true)

      h = 'Git deployment: ' + DateTime.now.to_s
      l = '-' * (h.length)
      o = "#{ h }\n#{ l }\n"

      puts o if @console
      @log << 'Ripple ' + o
    end

    def process
      temp_dir = @directory + '_temp'
      back_dir = @directory + '_backup'

      if Dir.exists? temp_dir
        FileUtils.rm_r temp_dir
      end

      if Dir.exists? back_dir
        FileUtils.rm_r back_dir
      end

      FileUtils.cp_r @directory, temp_dir
      Dir.chdir temp_dir

      io_log 'git reset --hard HEAD'
      io_log 'git pull origin master'

      # For PHP projects using composer
      if File.exists? 'composer.json'
        composer = 'composer.phar'
        unless File.exists? composer
          c = Net::HTTP.get_response(URI.parse('http://getcomposer.org/installer')).body
          File.write(composer, c)
        end

        if Dir.exists? 'vendor'
          FileUtils.rm_r 'vendor'
        end

        io_log "php #{ composer } self-update"
        io_log "php #{ composer } install --prefer-dist -o"
      end

      # For Ruby projects using bundler
      if File.exists? 'Gemfile'
        # Do some bundler stuff
        io_log 'sudo bundle install'
      end

      # Post executable files
      if @opts.has_key? 'post_exec'
        @opts['post_exec'].each do |e|
          io_log e
        end
      end

      # Move the current directory to the backup directory and move the temp directory to the current directory's place
      FileUtils.move @directory, back_dir
      FileUtils.move temp_dir, @directory

      if @opts.has_key? 'final_exec'
        Dir.chdir @directory
        @opts['final_exec'].each do |e|
          io_log e
        end
      end

      save_log @directory + '/deployment.log'
    end

    def io_log(command)
      io = IO.popen "#{ command } 2>&1"
      while (line = io.gets)
        puts line if @console

        @log << line
      end
    end

    def save_log(filename)
      @log.rewind
      File.write(filename, @log.read)
      @log.close
      @log.unlink
    end
  end
end
