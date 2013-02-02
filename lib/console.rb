require_relative 'utilities'

class Console
  @root, @parent, @args, @project = nil

  def initialize(args)
    @root   = File.dirname(File.dirname(File.expand_path(__FILE__)))
    @parent = File.dirname(@root)
    @args   = args
  end

  def update
    project_ripple = project_dir + '/ripple.yml'

    opts = (File.exists? project_ripple) ? Utilities.get_config(project_ripple) : {}
    opts = {} unless opts

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

