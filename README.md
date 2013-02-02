Ripple
======

__NOTE: Ripple is still currently under active development, while I migrate existing functionality from Giply__

Rippls is a git-based deployment server written in Ruby. This server is meant as a more robust replacement for the [Giply](http://github.com/thoom/giply-server)
server. It is built on Sinatra and will update Git projects. It provides additional functionality built in both Ruby
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

    post_exec:
      - rm -rf cache
      - mkdir cache
      - chmod 777 cache
    final_exec:
      - sudo /etc/init.d/thin restart

Assumptions
-----------

 1. The server expects to be located in a subdirectory of the same parent directory as the projects it manages (for instance, inside of `/var/www`).
 2. The server web root should be the included `public` directory.
 3. The server uses HTTP Basic Authentication. Preferrably, you should use Basic Authentication over SSL.
 4. The server expects pretty URLs, in the format: `project_name/security_secret`.
    * *project_name* is the name of the working directory (in your /var/www folder).
    * *security_secret* is a secret you set on a per project basis in your ripple_config.yml file. A sample ripple_config file:
    
		    username: myuser
		    password: secretpassword
		    secret:
		      myproject: abc123456

    So an example of a POST url for Bitbucket or Github for my server:

        https://myuser:secretpassword@deploy.myserver.com/myproject/abc123456

    The server script is built around projects that I have on Github and Bitbucket. Both of these providers POST to the server
    with a json string to the _payload_ key. The server stores the JSON string in a file: **ripple_payload.json**. This provides
    any of the *post_exec* scripts access to the payload data for processing.

 4. Any project that you want to have updated by Ripple needs to have its git repo initialized and origin added. Connecting to the
    repository using SSH means that you also need to make sure that the web user running Ripple has the SSH key to connect
    to the server. As an example:

        sudo su www-data
        cd /var/www/mysite
        git init
        git remote add origin git@bitbucket.org:myacct/myrepo.git
        git pull origin master

    If you get an error pulling the origin, it probably means that the SSH key is missing or not approved to access the repo.
    However, if you can successfully pull the origin using your web user (like `www-data`), Ripple should work fine.

  5. You know how to set up a webserver in Ruby. I use an Nginx + thin set up. Since there are so many different preferences and options, it's up to you to figure out how you want to host this service on your server.

Installation
------------

### Prerequisites

 1. Ruby and Gem installed : `sudo apt-get install make ruby1.9.3 build-essential libcurl4-openssl-dev zlib1g-dev`.
 2. Bundler installed: `sudo gem install bundle`.
 3. Web user has sudo access to bundle (i.e. in a sudoers.d file):

        Cmnd_Alias RIPPLEBUNDLE=/usr/local/bin/bundle
        www-data ALL=NOPASSWD: RIPPLEBUNDLE


### Ripple installer
 1. Log in as your web user: i.e. `sudo su - www-data`.
 2. To install, first just check out the code to the directory of your choice. I use something like */var/www/deploy*.

        git init
        git remote add origin git://github.com/thoom/ripple.git
        git pull origin master

 3. Run the install script using __self-update__.
 4. Now, anytime you want to update to the latest version, just run:

        self-update

 5. Depending on your server, you may need to restart it.

Command line console
--------------------
In addition to the server that automatically updates a site, there are a few console commands that you can run:

### Update

To update a site (note that since this isn't a POST, there is no payload!):

    console --update mysite

To restore to the last backup (if one exists):

    console --restore mysite

TODO (in no particular order)
-----------------------------

1. Add locking, so if a request comes for a project while another is still processing, it won't write on top of the other
2. Add configuration for number of stored backups (with a basic default)
3. Add console script for restoring from backup
4. Update documentation with sample ripple configuration options
5. Add environment specific configuration support
6. Add overrides for composer options, including using a central composer.phar file
7. Add overrides for items like the git configuration (using a branch instead of master for instance)

References
----------

There are two blog posts that directly inspired Giply, and its successor Ripple:

 1. http://seancoates.com/blogs/deploy-on-push-from-github
 2. http://brandonsummers.name/blog/2012/02/10/using-bitbucket-for-automated-deployments
