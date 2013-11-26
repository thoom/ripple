require 'net/http'
require 'fileutils'
require 'tempfile'
require 'open4'

module Ripple
  class Git
    def initialize(directory, opts)
      @directory = directory
      @opts      = opts
      @log       = Tempfile.new('ripple-server')

      @backup_date   = DateTime.now.strftime('%y%m%dT%H%M%S')
      @backup_prefix = @directory + '_'
      @backup_dir    = @backup_prefix + @backup_date

      @console = (opts.has_key?(:console) && opts[:console] == true)

      h = 'Git deployment: ' + DateTime.now.to_s
      l = '-' * (h.length)
      o = "#{ h }\n#{ l }\n"

      puts o if @console
      @log << 'Ripple ' + o
    end

    def clone
      Dir.mkdir @backup_dir

      Dir.chdir @backup_dir do
        io_log 'git init'
        io_log "git remote add origin #{ @opts[:repo] }"
      end

      post_process @backup_dir
    end

    def process
      backups = Dir.glob(@backup_prefix + '*')
      path    = (File.symlink? @directory) ? File.readlink(@directory) : @directory

      if backups.length > @opts[:backups]
        backups.sort!
        extra = backups.length - @opts[:backups]
        backups.slice(0...extra).each do |b|
          FileUtils.rm_r b unless path == b
          msg = "Deleted: #{ b }"

          puts msg if @console
          @log << msg + "\n"
        end
      end

      FileUtils.rm_r @backup_dir if Dir.exists? @backup_dir
      FileUtils.cp_r path, @backup_dir
      File.delete @backup_dir + '/deployment.log' if File.exists? @backup_dir + '/deployment.log'

      Dir.chdir @backup_dir do
        io_log 'git reset --hard HEAD'
      end

      post_process @backup_dir
    end

    def post_process(temp_dir)
      Dir.chdir temp_dir do
        io_log "git pull #{ @opts[:git][:remote] } #{ @opts[:git][:branch] }"

        # For PHP projects using composer
        if File.exists? 'composer.json'
          composer = @opts[:composer].has_key?(:path) ? @opts[:composer][:path] : temp_dir + '/composer.phar'
          unless File.exists? composer
            c = Net::HTTP.get_response(URI.parse('http://getcomposer.org/installer')).body
            File.write(composer, c)
          end

          FileUtils.rm_r 'vendor' if @opts[:composer][:vendor] == 'clean' && Dir.exists?('vendor')

          io_log "php #{ composer } self-update" if FileTest.writable? File.dirname(composer)
          io_log "php #{ composer } #{ @opts[:composer][:command] } --prefer-#{ @opts[:composer][:source] } #{ @opts[:composer][:flags] }"
        end

        # For Ruby projects using bundler
        if File.exists? 'Gemfile'
          # Do some bundler stuff
          io_log 'sudo bundle install'
        end

        # Post executable files
        if @opts.has_key? :post_exec
          msg = 'Running post_exec scripts...'
          puts msg if @console
          @log << msg + "\n"

          @opts[:post_exec].each do |e|
            puts e if @console
            @log << e + "\n"

            io_log e
          end
        end
      end

      # Move the current directory to the backup directory and move the temp directory to the current directory's place
      FileUtils.rm_r @directory if File.exists? @directory

      File.symlink(temp_dir, @directory)
      if @opts.has_key? :final_exec
        msg = 'Running final_exec scripts...'
        puts msg if @console
        @log << msg + "\n"

        Dir.chdir @directory do
          @opts[:final_exec].each do |e|
            puts e if @console
            @log << e + "\n"

            io_log e
          end
        end
      end

      save_log @directory + '/deployment.log'
    end

    def io_log(command)
      pid, stdin, stdout, sterr = Open4::popen4('/bin/sh')

      stdin.puts command
      stdin.close

      while (line = stdout.gets)
        puts line if @console

        @log << line
      end
      
      #io = IO.popen "#{ command }"
      #while (line = io.gets)
        #puts line if @console

        #@log << line
      #end
      #io.close
    end

    def save_log(filename)
      @log.rewind
      File.write(filename, @log.read)
      @log.close
      @log.unlink
    end
  end
end
