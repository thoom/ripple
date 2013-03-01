Ripple
======

Ripple is a git-based deployment server written in Ruby. This server is meant as a more robust replacement for the [Giply](http://github.com/thoom/giply-server)
server. It is built on Sinatra and will update Git projects. It provides additional functionality for projects built in both Ruby
(updating dependencies using [Bundler](http://gembundler.com)) and PHP (updating dependencies using [Composer](https://getcomposer.org)).

This server allows me to have a single domain (i.e. deploy.myserver.com) that I can use to manage POST deployments for all
of my projects on the server. For larger projects with multiple collaborators, I would recommend using a real CI server.

What does it do?
----------------
This script does all of the work pulling the latest data from the Git repo. It will look for a __ripple.yml__ file in the
project's working directory to overwrite any of the default variables. Additionally, if a __composer.json__ file exists
in the project's working directory, it will attempt to download (if it's not already in the working directory)
and run the composer.phar file. If a __Gemfile__ exists, it will attempt to run Bundler.

### ripple.yml
This YAML-based configuration file can overwrite basic information such as the log name, and can include an array
of executable strings that will be run after the git repo has been updated and composer has been run. For example,
you could remove a cache directory and re-add it.

    :composer:
      :path: /usr/local/bin/composer.phar   #If missing, composer will be downloaded to the folder
      :vendor: clean                        #If vendor=clean, the vendor directly will be deleted and redownloaded
      :command: install                     #Either "install" or "update"
      :source: dist                         #Either "dist" or "source"
      :flags: -o                            #Other flags
    :git:
      :branch: master                       #The name of the branch to pull from
      :remote: origin                       #The name of the remote to pull from
    :post_exec:
      - rm -rf cache
      - mkdir cache
      - chmod 777 cache
    :final_exec:
      - sudo /etc/init.d/thin restart

Assumptions
-----------

 1. You know how to set up a webserver in Ruby. I use an Nginx + thin set up. Since there are so many different preferences and options, it's up to you to figure out how you want to host this service on your server.
 2. The server expects to be located in a subdirectory of the same parent directory as the projects it manages (for instance, inside of `/var/www`).
 3. The server web root should be the included `public` directory.
 4. The server uses HTTP Basic Authentication. Preferrably, you should use Basic Authentication over SSL.
 5. The server expects pretty URLs, in the format: `project_name/security_secret`.
    * *project_name* is the name of the working directory (in your /var/www folder).
    * *security_secret* is a secret you set on a per project basis in your ripple_config.yml file. A sample ripple_config file:
    
		    :username: myuser
		    :password: hash of secretpassword
		    :secret:
		      myproject: hash of abc123456

    So an example of a POST url for Bitbucket or Github for my server:

        https://myuser:secretpassword@deploy.myserver.com/myproject/abc123456

    The server script is built around projects that I have on Github and Bitbucket. Both of these providers POST to the server
    with a json string to the _payload_ key. The server stores the JSON string in a file: **payload.json**. This provides
    any of the *post_exec* scripts access to the payload data for processing.

 4. Any project that you want to have updated by Ripple needs to have its git repo initialized and origin added. Connecting to the
    repository using SSH means that you also need to make sure that the user running Ripple has the SSH key to connect
    to the server. As an example:

        sudo su deploy
        console --init mysite (it will prompt you for various data it needs)

    If you get an error pulling the origin, it probably means that the SSH key is missing or not approved to access the repo.
    However, if you can successfully pull the origin using your user (like `deploy`), Ripple should work fine.

Installation
------------

### Prerequisites

 1. Ruby and Gem installed : `sudo apt-get install make ruby1.9.3 build-essential libcurl4-openssl-dev zlib1g-dev`.
 2. Bundler installed: `sudo gem install bundle`.
 3. User has sudo access to bundle (i.e. in a sudoers.d file):

        Cmnd_Alias RIPPLEBUNDLE=/usr/local/bin/bundle
        deploy ALL=NOPASSWD: RIPPLEBUNDLE

### Ripple installer
 1. Log in as your user: i.e. `sudo su - deploy`.
 2. To install, first just check out the code to the directory of your choice. I use something like */var/www/deploy*.

        git init
        git remote add origin git://github.com/thoom/ripple.git
        git pull origin master

 3. Run the install script using `console --self-update`.
 4. Now, anytime you want to update to the latest version, just run:

	    console --self-update

 5. Depending on your server, you may need to restart it.

Command line console
--------------------
In addition to the server that automatically updates a site, there are a few console commands that you can run:

To initialize a repo:

    console --init mysite (it will prompt for the data it needs)

To restore to a stored backup (if one exists):

    console --restore mysite

To update to the latest ripple version:

    console --self-update

To change the ripple username, password, stored backup number:

    console --self-config (asks for the password, so not stored in bash history)

To update a site (note that since this isn't a POST, there is no payload!):

    console --update mysite

To update a site's secret:

    console --config mysite (asks for the site secret, so not stored in bash history)

TODO (in no particular order)
-----------------------------

1. Add locking, so if a request comes for a project while another is still processing, it won't write on top of the other
2. Update documentation with sample ripple configuration options

References
----------

There are two blog posts that directly inspired Giply, and its successor Ripple:

 1. http://seancoates.com/blogs/deploy-on-push-from-github
 2. http://brandonsummers.name/blog/2012/02/10/using-bitbucket-for-automated-deployments
