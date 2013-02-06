require_relative 'utilities'

module Ripple
  class Console
    @root, @parent, @args, @project = nil

    def initialize(args)
      @root   = File.dirname(File.dirname(File.expand_path(__FILE__)))
      @parent = File.dirname(@root)
      @args   = args
    end

    def init_site

      repo = "git@bitbucket.org:myacct/myrepo.git"

      Dir.chdir project_dir
      `git init`
      `git remote add origin #{ repo }`
      `git pull origin master`
    end

    def self_update
      puts "Updating Ripple files"
      puts `git reset --hard HEAD`
      puts `git pull origin master`
      puts `sudo bundle install`
    end

    def update
      project_ripple = project_dir + '/ripple.yml'
      opts           = Utilities.get_config(project_ripple)
      opts[:console] = true

      require_relative 'git'
      r = Git.new(project_dir, opts)
      r.process
    end

    def restore
      puts 'Coming soon!'
    end

    def project_dir
      if @project == nil
        Utilities.stop 'Project name missing' unless @args.length > 0

        proj = @parent + '/' + @args[0]
        Utilities.stop 'Invalid project' unless (File.exists? proj) || (File.directory? proj + '/.git')

        @project = proj
      end

      @project
    end
  end
end

