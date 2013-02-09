require 'io/console'
require_relative 'utilities'
require_relative 'git'

module Ripple
  class Console
    @args, @project_dir, @project_name = nil

    def initialize(args)
      @args = args
    end

    def self_config
      puts 'Configuring Ripple'
      puts "------------------\n"

      config = Utilities.get_ripple_config

      print 'Do you want to change the username? [yN] '
      if %w(Y YES YEP YEAH YESSIR).index STDIN.gets.strip.upcase
        username = ''

        while username.empty?
          print 'What is the new username? '
          username = STDIN.gets.strip
        end

        config[:username] = username
      end

      print 'Do you want to change the password? [yN] '
      if %w(Y YES YEP YEAH YESSIR).index STDIN.gets.strip.upcase
        pass  = false
        vpass = true

        until pass == vpass
          print 'What is the new password? '
          input = STDIN.noecho(&:gets).strip

          if input.empty?
            puts ''
            next
          end

          print "\nRepeat the new password: "
          verify_input = STDIN.noecho(&:gets).strip

          if verify_input.empty?
            puts ''
            next
          end

          puts ''
          if input == verify_input
            pass  = input
            vpass = input
          end

        end

        config[:password] = Utilities.hash pass
      end

      print 'Do you want to change the number of site backups stored? [yN] '
      if %w(Y YES YEP YEAH YESSIR).index STDIN.gets.strip.upcase
        backup = ''

        while backup.empty?
          print 'How many backups do you want stored? '
          input = STDIN.gets.strip

          backup = input if Float(input) rescue ''
        end

        config[:backups] = backup.to_i
      end

      Utilities.save_ripple_config config
    end

    def self_update
      puts 'Updating Ripple files'
      puts "---------------------\n"

      puts `git reset --hard HEAD`
      puts `git pull origin master`
      puts `sudo bundle install`

      print 'Do you want to update the ripple config?? [yN]'
      if %w(Y YES YEP YEAH YESSIR).index STDIN.gets.strip.upcase
        self.self_config
      end
    end

    def site_config
      h = "Configuring #{ project_name }"
      l = '-' * h.length
      puts h + "\n" + l + "\n"

      print "Do you want to change the site secret for #{ project_name }? [yN] "
      Utilities.stop 'Exiting without switching as requested' unless %w(Y YES YEP YEAH YESSIR).index STDIN.gets.strip.upcase

      save_site_secret
    end

    def site_init
      h = "Initializing #{ project_name }"
      l = '-' * h.length
      puts h + "\n" + l + "\n"

      repo = ''

      while repo.empty?
        print 'What is the Git repo URL? '
        repo = STDIN.gets.strip
      end

      save_site_secret

      parent = Utilities.parent
      pd     = parent + '/' + project_name
      if File.exists? pd
        print 'Do you want to use the existing folder? [yN] '

      else
        opts           = Utilities.get_project_config project_name
        opts[:console] = true
        opts[:repo]    = repo

        Git.new(pd, opts).clone
      end

    end

    def site_restore
      h = "Restoring #{ project_name }"
      l = '-' * h.length
      puts h + "\n" + l + "\n"

      Utilities.stop 'Invalid project name' unless File.symlink? project_dir

      paths = Dir.glob(project_dir + '_*')

      Utilities.stop 'No backups to restore to!' unless paths.length > 1

      real_path = File.readlink(project_dir)
      paths.sort!

      i = 0
      paths.each { |v| puts (i + 1).to_s + ': ' + File.basename(v) + (v == real_path ? ' <== current version' : ''); i += 1 }

      path = ''
      o    = ''
      while path.empty?
        print "Which backup do you want to restore to (1 - #{ i })? "
        input = STDIN.gets.strip
        o = input if Float(input) rescue ''

        next if o.empty?
        o = o.to_i
        unless o < 1 || o > paths.length
          path = paths[o - 1]
          Utilities.stop "\nCurrent revision. Nothing to restore" if path == real_path

          print "You are about to restore to '#{ File.basename(path) }'. Are you sure? [yN] "
          path = '' unless %w(Y YES YEP YEAH YESSIR).index STDIN.gets.strip.upcase
        end

        FileUtils.rm_r project_dir if File.exists? project_dir

        puts "\nProject restored to #{ File.basename(path) }." if File.symlink(path, project_dir)
      end
    end

    def site_update
      h = "Updating #{ project_name }"
      l = '-' * h.length
      puts h + "\n" + l + "\n"

      opts           = Utilities.get_project_config project_name
      opts[:console] = true

      Git.new(project_dir, opts).process
    end


    private
    def save_site_secret
      config = Utilities.get_ripple_config

      pass  = false
      vpass = true

      until pass == vpass
        print 'What is the new site secret? '
        input = STDIN.noecho(&:gets).strip

        if input.empty?
          puts ''
          next
        end

        print "\nRepeat the new site secret: "
        verify_input = STDIN.noecho(&:gets).strip

        if verify_input.empty?
          puts ''
          next
        end

        puts ''
        if input == verify_input
          pass  = input
          vpass = input
        end
      end

      config[:secret] = {} unless config.has_key? :secret
      config[:secret][project_name] = Utilities.hash pass
      Utilities.save_ripple_config config
    end

    def project_name
      if @project_name == nil
        Utilities.stop 'Project name missing' unless @args.length > 0
        @project_name = @args[0]
      end

      @project_name
    end

    def project_dir
      if @project_dir == nil
        Utilities.stop 'Project name missing' unless project_name

        proj = Utilities.parent + '/' + project_name
        Utilities.stop 'Invalid project' unless (File.exists? proj) || (File.directory? proj + '/.git')

        @project_dir = proj
      end

      @project_dir
    end
  end
end
