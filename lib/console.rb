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
      config = Utilities.get_ripple_config

      print 'Do you want to change the username? [yN] '
      result = STDIN.gets

      if %w(Y YES YEP YEAH YESSIR).index result.strip.upcase
        username = ''

        while username.empty?
          print 'What is the new username? '
          username = STDIN.gets.strip
        end

        config[:username] = username
      end

      print 'Do you want to change the password? [yN] '
      result = STDIN.gets

      if %w(Y YES YEP YEAH YESSIR).index result.strip.upcase
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

      print 'Do you want to change the number of site backups stored? [yN]'
      result = STDIN.gets

      if %w(Y YES YEP YEAH YESSIR).index result.strip.upcase
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
      result = STDIN.gets

      if %w(Y YES YEP YEAH YESSIR).index result.strip.upcase
        self.self_config
      end
    end

    def site_config
      print "Do you want to change the site secret for #{ project_name }? [yN] "
      result = STDIN.gets

      Utilities.stop 'Exiting without switching as requested' unless %w(Y YES YEP YEAH YESSIR).index result.strip.upcase

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
      pd =  parent + '/' + project_name
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
      puts 'Coming soon!'
    end

    def site_update
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