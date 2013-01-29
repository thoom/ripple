Ripple
======

__NOTE: Ripple is still currently under active development, while I migrate existing functionality from Giply__

Git-based deployment server written in Ruby. This server is meant as a more robust replacement for the [Giply](http://github.com/thoom/giply-server)
server. It is built on Sinatra and will update Git projects. It provides additional functionality built in both Ruby
(updating dependencies using [Bundler](http://gembundler.com)) and PHP (updating dependencies using [Composer](https://getcomposer.org)).

This server allows me to have a single domain (i.e. deploy.myserver.com) that I can use to manage POST deployments for all
of my projects on the server.

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

####Note
All of the post_exec scripts are run as command line scripts and are not included in the server script itself.

Assumptions
-----------

 1. The server expects to be located in a subdirectory of the same parent directory as the projects it manages (for instance, inside of `/var/www`).
 2. The server web root should be the included `public` directory.
 3. The server expects pretty URLs, in the format: `project_name/security_hash`.
    * *project_name* is the name of the working directory (in your /var/www folder).
    * *security_hash* is by default a simple sha1 hash of the string `#{parent_dir}/#{project_name}`. To provide your own
    security hash, you can add a hash object with the project name as a key in your ripple_config.yml file:
    
		    hash:
		      mysite: abc123456

    So an example of a POST url for Bitbucket or Github for my server:

        http://deploy.myserver.com/mysite/ff56634640221a6b2716d276361162cd

    The server script is built around projects that I have on Github and Bitbucket. Both of these providers POST to the server
    with a json string to the _payload_ key. The server stores the JSON string in a file: **ripple_payload.json**. This provides
    any of the *post_exec* scripts access to the payload data for processing.

 4. Any project that you want to have updated by Ripple needs to have its git repo initialized and origin added. Connecting to the
    repository using SSH means that you also need to make sure that the web user running Ripple has the SSH key to connect
    to the server. As an example:

        sudo su www-data
        cd /var/www/mysite
        git init
        git remote add origin git@bitbucket.org:myacct/myacct.git
        git pull origin master

    If you get an error pulling the origin, it probably means that the SSH key is missing or not approved to access the repo.
    However, if you can successfully pull the origin using your web user (like `www-data`), Ripple should work fine.

Installation
------------

Note: There is an assumption here that you know how to set up Apache or Nginx for pretty URLs. I personally use Nginx
for my projects, but even with Apache I like putting my rewrite rules in a vhost file over .htaccess. For that reason,
I'm not including an .htaccess file in the web directory.

 1. To install, first just check out the code to the directory of your choice. I use something like */var/www/deploy*.

        git init
        git remote add origin git://github.com/thoom/ripple.git
        git pull origin master

 2. Run the install script using __ruby self-update.rb__. Make sure that the user running this file has permission to write to
    this directory.
 3. Now, anytime you want to update to the latest version, just run:

        ruby self-update.rb

To run the server from the command line
---------------------------------------

You can run the server from the command line:

    ruby console.rb pull mysite

TODO (in no particular order)
-----------------------------

1. Complete migration of Giply functionality
2. Added deployment logging
3. Add console script for manually deployment
4. Convert to using Sinatra for Rack-compatibility
5. Update documentation with FAQs

References
----------

There are two blog posts that directly inspired Giply, and its successor Ripple:

 1. http://seancoates.com/blogs/deploy-on-push-from-github
 2. http://brandonsummers.name/blog/2012/02/10/using-bitbucket-for-automated-deployments
