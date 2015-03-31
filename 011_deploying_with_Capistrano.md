We're going to use an automated deployment tool called [Capistrano](http://capistranorb.com/) to both do our initial deploy and future deploys.  Capistrano is frequently used with Ruby on Rails applications (it is written in Ruby) but can be used with other languages as well.

# Setting up the Rails application
```bash
  vagrant@workshop $ cd ~/widgetworld
```

Open up the Gemfile

```bash
  vagrant@workshop $ vim Gemfile
```

Add this content

```bash
group :development do
  gem 'capistrano',  '~> 3.1'
  gem 'capistrano-rails', '~> 1.1'
  gem 'capistrano-rvm'
end
```

Then run:

```bash
  vagrant@workshop $ bundle
```

This will install all the necessary ruby gems for this application, including the ones needed for running Capistrano.

If you receive this error:

```bash
  Can't find the 'libpq-fe.h header
  *** extconf.rb failed ***
  Could not create Makefile due to some reason, probably lack of necessary
  libraries and/or headers.
```

Run this on your development VM:

```bash
  vagrant@workshop $ sudo apt-get install postgresql-client libpq5 libpq-dev
  vagrant@workshop $ sudo gem install pg -v '0.17.1'
```

Then rerun:

```bash
  vagrant@workshop $ bundle
```

If you continue to get the same error, comment out the pg gem line in your Gemfile

```bash
  #gem 'pg'
```

(It was already installed when you ran "sudo gem install pg -v '0.17.1'")

Then rerun:

```bash
  vagrant@workshop $ bundle
```

# Installing and Configuring Capistrano

There is also some special additional installation for capistrano.  Run this command, which will add some additional Capistrano config files.

```bash
  vagrant@workshop $ cap install
```

Next, open your Capfile in your favorite editor

```bash
  vagrant@workshop $ vim Capfile
```

Uncomment these lines

```bash
  # require 'capistrano/rvm'
  # require 'capistrano/bundler'
```

So it looks like this

```bash
  require 'capistrano/rvm'
  require 'capistrano/bundler'
```

 Next, open up the config/deploy.rb file with your favorite text editor

```bash
  vagrant@workshop $ vim config/deploy.rb
```

 Change these to lines
 ```bash
 set :application, 'my_app_name'
 set :repo_url, 'git@example.com:me/my_repo.git'
 ```

 To this

 ```bash
 set :application, 'widgetworld'
 set :repo_url, 'git@github.com:nellshamrell/widgetworld.git'
 ```

 Then change this line
 ```bash
 # set :deploy_to, '/var/www/my_app_name'
 ```

 To this

 ```bash
  set :deploy_to, '/var/www/widgetworld'
```

Then uncomment this line

```bash
  set :scm, :git
```

And uncomment this line

```bash
  set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')
```

Finally, uncomment this line
```bash
   set :linked_dirs, fetch(:linked_dirs, []).push('bin', 'log', 'tmp/pids', 'tm    p/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')
 ```

 And add this sequence of lines right after "namespace :deploy do"
 ```bash
 namespace :deploy do


 desc 'Restart application'
   task :restart do
     on roles(:app), in: :sequence, wait: 5 do
      # This restarts Passenger
       execute :mkdir, '-p', "#{ release_path }/tmp"
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart
```

# Modifying our Chef recipe

In the changes we just made to config/deploy.rb, we specified that we would be deploying our application to a directory in /var/www on the VM.

We need to change the owner of this directory to deploy

First, change directories back to your cookbook.

```bash
  vagrant@workshop $ cd ~/fresh_start_web_server_repo/cookbooks/my_web_server_cookbook
```

Let's create a new recipe, this one specifically for the app.

```bash
  vagrant@workshop $ chef generate recipe app
```

Now we need to create the directory where our server specs will live:

```bash
  vagrant@workshop $ mkdir -p test/integration/app/serverspec
```

And create the test file

```bash
  vagrant@workshop $ touch test/integration/app/serverspec/app_spec.rb
```

And we need to be able to access a spec_helper similar to the one living in test/integration/default/serverspec.  In this case, let's copy that one into our new integration test directory.

```bash
  vagrant@workshop $ cp test/integration/default/serverspec/spec_helper.rb test/integration/app/serverspec
```

Now let's create some tests, checking that the /var/www directory is owned by deploy and grouped in the deploy group.

# Setting ownership of the www directory

test/integration/app/serverspec/app_spec.rb
```bash
require 'spec_helper'
describe 'my_web_server_cookbook::app' do
  describe file('/var/www') do
    it { should be_owned_by 'deploy' }
  end

  describe file('/var/www') do
    it { should be_grouped_into 'deploy' }
  end
end
```

Now we need to add this test suite to our .kitchen.yml file so Test Kitchen will run it.

Open up you .kitchen.yml file

```bash
  vagrant@workshop $ vim .kitchen.yml
```

And add this content:

```bash
suites:
- name: default
  run_list:
    - recipe[my_web_server_cookbook::default]
  attributes:
- name: ruby
  run_list:
    - recipe[my_web_server_cookbook::ruby]
  attributes:
- name: passenger
  run_list:
    - recipe[my_web_server_cookbook::passenger]
  attributes:
- name: postgresql
  run_list:
    - recipe[my_web_server_cookbook::postgresql]
  attributes:
- name: user
  run_list:
    - recipe[my_web_server_cookbook::user]
  attributes:
- name: app
  run_list:
    - recipe[my_web_server_cookbook::app]
  attributes:
```

Next you'll need to create a new test instance for the new suite:

```bash
  vagrant@workshop $ kitchen create app-ubuntu-14-04-x64
```

And then set it up with Chef:

```bash
  vagrant@workshop $ kitchen setup app-ubuntu-14-04-x64
```

Now, run the tests:

```bash
  vagrant@workshop $ kitchen verify app-ubuntu-14-04-x64
```

And they should fail.

Now let's make them pass.  Open up recipes/app.rb and add this content:

```bash
include_recipe 'my_web_server_cookbook::default'
include_recipe 'my_web_server_cookbook::user'

execute 'change owner and group' do
  command "sudo chown deploy:deploy /var/www"
  action :run
 end
```

Now apply the changes:

```bash
  vagrant@workshop $ kitchen converge app-ubuntu-14-04-x64
```

And run the tests again

```bash
  vagrant@workshop $ kitchen verify app-ubuntu-14-04-x64
```

And they should pass!

Now we need to add this to our node's run list.  Open up nodes/[node's ip address].json and add this recipe to your run list:

```bash
  {
    "run_list": [
      "recipe[my_web_server_cookbook::default]",
      "recipe[my_web_server_cookbook::passenger]",
      "recipe[my_web_server_cookbook::ruby]",
      "recipe[my_web_server_cookbook::postgresql]",
      "recipe[my_web_server_cookbook::user]",
      "recipe[my_web_server_cookbook::app]"
    ]
  }
```

Now, to avoid installing passenger, etc. again, modify your run list so it looks like this:

```bash
  {
    "run_list": [
      "recipe[my_web_server_cookbook::app]"
    ]
  }
```

This way it will only apply changes from our app recipe and avoid a lengthy reconverge.

Now, apply this to your staging node with:

```bash
  vagrant@workshop $ knife solo cook root@[your staging instance ip]
```

## Setting Capistrano roles

Now change back to your widgetworld directory

```bash
  vagrant@workshop $ cd ~/widgetworld
```

Take a look at the various deploy configs:

```bash
  vagrant@workshop $ ls config/deploy
```

You should see two configs, each corresponding to a different environment.

```bash
  production.rb  staging.rb
```

Let's use the staging config for right now.


Open up the config/deploy/staging.rb file. Uncomment and change these lines:

```bash
   role :app, %w{deploy@example.com}, my_property: :my_value
   role :web, %w{user1@primary.com user2@additional.com}, other_property: :other_value
   role :db,  %w{deploy@example.com}
```

To this

(Make sure to substitute the ip address for your testing node)

```bash
  role :app, %w{deploy@#{ip_address}}
  role :web, %w{deploy@#{ip_address}}
  role :db,  %w{deploy@#{ip_address}}
```

And uncomment and change this line

```bash
  server 'example.com', user: 'deploy', roles: %w{app db web}, my_property: :my_value
```

To this:

(Make sure to substitute the ip address for your testing node)

```bash
  server '#{ip_address}', user: 'deploy', roles: %w{app db web}
```

Now let's check whether our application is ready to deploy to testing.  Run this command:

```bash
  vagrant@workshop $ cap staging deploy:check
```

Whoops, looks like it's prompting for a password.  This is because our ssh key is not on the testing instance for the deploy user.  Let's get that fixed.

## Adding your SSH Key

Change directories back to your chef cookbook.

```bash
  vagrant@workshop $ cd ~/fresh_start_chef_repo/cookbooks/my_web_server_cookbook/
```

Normally, we would add the SSH key through a user databag.  For the sake of time, we're going to use a template instead in this workshop.  However, a databag would be a better way to do this in a "real world" environment.  To learn more about databags, see [the Chef documentation on databags](http://docs.chef.io/data_bags.html).

First, we need to add an .ssh director to the deploy folder in the /home directory.  Let's add this into the user recipe.  Open up the user test file and add this test

test/integration/user/serverspec/user_spec.rb
```bash
  describe file('/home/deploy/.ssh') do
    it { should be_directory }
  end
```

And run the test:

```bash
  vagrant@workshop $ kitchen verify user-ubuntu-14-04-x64
```

And, as expected, it fails.  Now let's make it pass.

Open up recipes/user.rb and add this content.

```bash
  execute 'create .ssh directory' do
    command "sudo mkdir /home/deploy/.ssh"
    action :run
    not_if { ::File.exists?("/home/deploy/.ssh")}
  end
```

Then converge and run the tests again.

```bash
  vagrant@workshop $ kitchen converge user-ubuntu-14-04-x64
```

```bash
  vagrant@workshop $ kitchen verify user-ubuntu-14-04-x64
```

And it passes!

Now we need to add in an authorized_keys file to this new directory, then populate it with our ssh key.

First, a test.

test/integration/user/serverspec/user_spec.rb
```bash
  describe file('/home/deploy/.ssh/authorized_keys') do
    it { should be_file }
    its(:content) { should match /ssh-rsa.+devops workshop key/ }
  end
```

Then, as usual, run the tests.

```bash
  vagrant@workshop $ kitchen verify user-ubuntu-14-04-x64
```

And watch them fail.

Now let's make them pass.  We need a template with the SSH key in it.

Change directories back to your Chef repo directory

```bash
  vagrant@workshop $ cd ~/my_web_server_chef_repo
```

And generate the template.

```bash
  vagrant@workshop $ chef generate template cookbooks/my_web_server_cookbook ssh_key
```

Now change directories back to your cookbook directory:

```bash
  vagrant@workshop $ cd cookbooks/my_web_server_cookbook
```

Then open up the new template and add this content.

templates/default/ssh_key.erb
```bash
  [Paste in PUBLIC SSH Key provided by instructors]
```

Now add this into your recipes/user.rb file:

```bash
  template '/home/deploy/.ssh/authorized_keys' do
    source 'ssh_key.erb'
  end
```

And converge, then re-run the tests.

```bash
  vagrant@workshop $ kitchen converge user-ubuntu-14-04-x64
```

```bash
  vagrant@workshop $ kitchen verify user-ubuntu-14-04-x64
```

And they should pass!

Now let's apply these changes to our testing node.  Run this command:

```bash
  vagrant@workshop $ knife solo cook root@[testing_node_ip_address]
```

## Deploying again

Let's switch back to the widgetworld directory.

```bash
  vagrant@workshop $ cd ~/widgetworld
```

And try the deploy check again.

```bash
  vagrant@workshop $ cap staging deploy:check
```

If you receive git error, do this:

```bash
  vagrant@workshop $ ssh-add ~/.ssh/id_rsa
```

And it fails again.  Let's take a look at that error:

```bash
  ERROR linked file /var/www/widgetworld/shared/config/database.yml does not exist
```

Capistrano expects to find a file that isn't there.  Let's get this taken care of.

[For the sake of time, we're not adding this file into our Chef cookbook.  However, extra credit points to any student who figures out how to!)

SSH into your test instance.

Notice that we're now ssh'ing in as the DEPLOY user.

```bash
  ssh deploy@[your staging instance]
```

Create and open this file on your VM.
```bash
  deploy@staging $ vim /var/www/widgetworld/shared/config/database.yml
```

And add this content:
```bash
# PostgreSQL. Versions 8.2 and up are supported.
#
# Install the pg driver:
#   gem install pg
# On OS X with Homebrew:
#   gem install pg -- --with-pg-config=/usr/local/bin/pg_config
# On OS X with MacPorts:
#   gem install pg -- --with-pg-config=/opt/local/lib/postgresql84/bin/pg_config
# On Windows:
#   gem install pg
#       Choose the win32 build.
#       Install PostgreSQL and put its /bin directory on your path.
#
# Configure Using Gemfile
# gem 'pg'
#
default: &default
  adapter: postgresql
  encoding: unicode
# For details on connection pooling, see rails configuration guide
# http://guides.rubyonrails.org/configuring.html#database-pooling
pool: 5

development:
  <<: *default
  database: widgetworld_development

# The specified database role being used to connect to postgres.
# To create additional roles in postgres see `$ createuser --help`.
# When left blank, postgres will use the default role. This is
# the same name as the operating system user that initialized the database.
username: nellshamrell

# The password associated with the postgres role (username).
#password:

# Connect on a TCP socket. Omitted by default since the client uses a
# domain socket that doesn't need configuration. Windows does not have
# domain sockets, so uncomment these lines.
#host: localhost

# The TCP port the server listens on. Defaults to 5432.
# If your server runs on a different port number, change accordingly.
#port: 5432

# Schema search path. The server defaults to $user,public
#schema_search_path: myapp,sharedapp,public

# Minimum log levels, in increasing order:
#   debug5, debug4, debug3, debug2, debug1,
#   log, notice, warning, error, fatal, and panic
# Defaults to warning.
#min_messages: notice

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  <<: *default
  database: widgetworld_test

# As with config/secrets.yml, you never want to store sensitive information,
# like your database password, in your source code. If your source code is
# ever seen by anyone, they now have access to your database.
#
# Instead, provide the password as a unix environment variable when you boot
# the app. Read http://guides.rubyonrails.org/configuring.html#configuring-a-database
# for a full rundown on how to provide these environment variables in a
# production deployment.
#
# On Heroku and other platform providers, you may have a full connection URL
# available as an environment variable. For example:
#
#   DATABASE_URL="postgres://myuser:mypass@localhost/somedatabase"
#
# You can use this database configuration with:
#
#   production:
#     url: <%= ENV['DATABASE_URL'] %>
#

staging:
  <<: *default
  database: widgetworld_staging
  username: deploy
  password: <%= ENV['WIDGETWORLD_DATABASE_PASSWORD'] %>

production:
  <<: *default
  database: widgetworld_production
  username: deploy
  password: <%= ENV['WIDGETWORLD_DATABASE_PASSWORD'] %>
```

Did you notice that the password refers to an environment variable?  This is because passwords can be dangerous to keep in source code.  Now we need to set that environment variable.

Let's set that environment variable now.  On your testing VM, run this command:

```bash
   vagrant@workshop $ export WIDGETWORLD_DATABASE_PASSWORD=[password you used in your chef recipe for the deploy user to login to postgres]
```

Then run the deploy check again.

```bash
  vagrant@workshop $ cap staging deploy:check
```

Whoops, another error, it's not finding a file it expects to be there.

```bash
  ERROR linked file /var/www/widgetworld/shared/config/secrets.yml does not exist on 45.55.153.64
```

Let's add that one in.  Just add an empty file for now and we'll come back to this later.

SSH into your staging instance:

```bash
  vagrant@workshop $ ssh deploy@[your staging instance ip]
```

And create this file: (we'll add content shortly)

```bash
  deploy@staging $ touch /var/www/widgetworld/shared/config/secrets.yml
```

Now exit out of your staging instance and, from your development VM, run:

```bash
  vagrant@workshop $ cap staging deploy:check
```

If it does not return an error and exits with a line similar to:

```bash
  DEBUG [7f34dcb9] Finished in 0.004 seconds with exit status 0 (successful).
```

Then we're ready to deploy for real!

## Deploying with Capistrano

Deploy with

```bash
  vagrant@workshop $ cap staging deploy
```

Whoops, another error:

```bash
  DEBUG [c880919a] Command: cd /var/www/widgetworld/releases/20150330230130 && /usr/local/rvm/bin/rvm default do bundle install --path /var/www/widgetworld/shared/bundle --without development test --deployment --quiet
  DEBUG [c880919a]        /usr/local/rvm/scripts/set: line 19: exec: bundle: not found
```

We need to install bundler on the VM (this is also something that we could capture in a Chef recipe)

SSH into your staging instance as the deploy user

```bash
  vagrant@workshop $ ssh deploy@[your staging instance ip]
```

Then run:

```bash
  deploy@staging $ sudo gem install bundler
```

Exit out of your staging instance, and run this command again

```bash
  vagrant@workshop $ cap staging deploy
```

And it looks like it worked!

The next thing we need to do is create our database.  Capistrano does not currently allow you to do this through the tool, so we're going to do it manually.

```bash
  vagrant@workshop $ ssh deploy@[your staging instance ip]
```

Then change directories to your current widgetworld deploy:

```bash
  deploy@staging $ cd /var/www/widgetworld/current
```

Then create your database.  (We're using a very common Ruby/Rails tool called [Rake](https://github.com/ruby/rake)

```bash
  deploy@staging $ RAILS_ENV=staging rake db:create
```

If you get no output, that means it was a success!

Exit out of your staging instance.

Back on your VM, make sure you're in your widgetworld directory:

```bash
  vagrant@workshop $ cd ~/widgetworld
```

Now that the database is created, we're going to set up the tables for our database.  Rails does this through [database migrations](http://edgeguides.rubyonrails.org/active_record_migrations.html).  Fortunately, Capistrano can do this for use.

Open up your Capfile

```bash
  vagrant@workshop $ vim Capfile
```

And uncomment this line:

```bash
 # require 'capistrano/rails/migrations'
```

So it looks like this:

```bash
  require 'capistrano/rails/migrations'
```

Now run your deploy again to run these migrations:

```bash
  vagrant@workshop $ cap staging deploy
```

If you see this output, the migration was successful!
```bash
  DEBUG [48ce67f9]        == 20141223043443 CreateWidgets: migrating ====================================
  DEBUG [48ce67f9]        -- create_table(:widgets)
  DEBUG [48ce67f9]           -> 0.0042s
  DEBUG [48ce67f9]        == 20141223043443 CreateWidgets: migrated (0.0043s) ===========================
```

Now it did work...but we received this warning.

```bash
  DEBUG [48ce67f9]        config.eager_load is set to nil. Please update your config/environments/*.rb files accordingly:
  DEBUG [48ce67f9]
  DEBUG [48ce67f9]          * development - set it to false
  DEBUG [48ce67f9]          * test - set it to false (unless you use a tool that preloads your test environment)
  DEBUG [48ce67f9]          * production - set it to true
```

Rails keeps different config files in the config/environments folders.  There's not one for staging by default.  Let's fix this:

SSH into your staging instance:

```bash
  vagrant@workshop $ ssh deploy@[your staging instance IP address]
```

Then change directories to your widgetworld directory

```bash
  vagrant@workshop $ cd /var/www/widgetworld
```

And run this command, we're going to give our staging instance the same eager_load config as our production instance.

```bash
  vagrant@workshop $ cp /var/www/widgetworld/current/config/environments/production.rb /var/www/widgetworld/current/config/environments/staging.rb
```

Now restart Apache to reload the rails application:

Now let's take a look at that IP address in your browser, will we see our newly running widgetworld application?  Not quite...we still see our custom Apache homepage.

## Making Apache aware of our site

Finally, we need to make Apache aware of our new site.

Make sure you're back in you Development VM, then change to your cookbook directory.

```bash
  vagrant@workshop $ cd ~/fresh_start_web_server_repo/cookbooks/my_web_server_cookbook
```

First, let's add a test to test/integration/app/serverspec/app.rb

```bash
  describe file('/etc/apache2/apache2.conf') do
    it { should be_file }
    its(:content) { should match /<VirtualHost \*:80>/ }
  end
```

Then run the test to watch it fail.

```bash
  vagrant@workshop $ kitchen verify app-ubuntu-14-04-x64
```

Now let's make it pass.

Modify your Apache config template.  Add these lines to the file (no worries if hardcoding the IP makes you twitch, we'll change that shortly).

Now create a new Apache 2 template for use with the app recipe.

You need to run the generate template command from your my_web_server_chef_repo directory

```bash
  vagrant@workshop $ cd ~/fresh_start_web_server_repo
```

```bash
  vagrant@workshop $ chef generate template cookbooks/my_web_server_cookbook app-apache2.conf
```

Now change directories back to your cookbook directory:

```bash
  vagrant@workshop $ cd cookbooks/my_web_server_cookbook
```

Now open up your new template file and add this content.


templates/default/app-apache2.conf.erb
```bash
# This is the main Apache server configuration file.  It contains the
# configuration directives that give the server its instructions.
# See http://httpd.apache.org/docs/2.4/ for detailed information about
# the directives and /usr/share/doc/apache2/README.Debian about Debian specific
# hints.
#
#
# Summary of how the Apache 2 configuration works in Debian:
# The Apache 2 web server configuration in Debian is quite different to
# upstream's suggested way to configure the web server. This is because Debian's
# default Apache2 installation attempts to make adding and removing modules,
# virtual hosts, and extra configuration directives as flexible as possible, in
# order to make automating the changes and administering the server as easy as
# possible.

# It is split into several files forming the configuration hierarchy outlined
# below, all located in the /etc/apache2/ directory:
#
#       /etc/apache2/
#       |-- apache2.conf
#       |       `--  ports.conf
#       |-- mods-enabled
#       |       |-- *.load
#       |       `-- *.conf
#       |-- conf-enabled
#       |       `-- *.conf
#       `-- sites-enabled
#               `-- *.conf
#
#
# * apache2.conf is the main configuration file (this file). It puts the pieces
#   together by including all remaining configuration files when starting up the
#   web server.
#
# * ports.conf is always included from the main configuration file. It is
#   supposed to determine listening ports for incoming connections which can be
#   customized anytime.
#
# * Configuration files in the mods-enabled/, conf-enabled/ and sites-enabled/
#   directories contain particular configuration snippets which manage modules,
#   global configuration fragments, or virtual host configurations,
#   respectively.
#
#   They are activated by symlinking available configuration files from their
#   respective *-available/ counterparts. These should be managed by using our
#   helpers a2enmod/a2dismod, a2ensite/a2dissite and a2enconf/a2disconf. See
#   their respective man pages for detailed information.
#
# * The binary is called apache2. Due to the use of environment variables, in
#   the default configuration, apache2 needs to be started/stopped with
#   /etc/init.d/apache2 or apache2ctl. Calling /usr/bin/apache2 directly will not
#   work with the default configuration.


# Global configuration
#

#
# ServerRoot: The top of the directory tree under which the server's
# configuration, error, and log files are kept.
#
# NOTE!  If you intend to place this on an NFS (or otherwise network)
# mounted filesystem then please read the Mutex documentation (available
# at <URL:http://httpd.apache.org/docs/2.4/mod/core.html#mutex>);
# you will save yourself a lot of trouble.
#
# Do NOT add a slash at the end of the directory path.
#
#ServerRoot "/etc/apache2"

#
# The accept serialization lock file MUST BE STORED ON A LOCAL DISK.
#
Mutex file:${APACHE_LOCK_DIR} default

#
# PidFile: The file in which the server should record its process
# identification number when it starts.
# This needs to be set in /etc/apache2/envvars
#
PidFile ${APACHE_PID_FILE}

#
# Timeout: The number of seconds before receives and sends time out.
#
Timeout 300

#
# KeepAlive: Whether or not to allow persistent connections (more than
# one request per connection). Set to "Off" to deactivate.
#
KeepAlive On

#
# MaxKeepAliveRequests: The maximum number of requests to allow
# during a persistent connection. Set to 0 to allow an unlimited amount.
# We recommend you leave this number high, for maximum performance.
#
MaxKeepAliveRequests 100

#
# KeepAliveTimeout: Number of seconds to wait for the next request from the
# same client on the same connection.
#
KeepAliveTimeout 5


# These need to be set in /etc/apache2/envvars
User ${APACHE_RUN_USER}
Group ${APACHE_RUN_GROUP}

#
# HostnameLookups: Log the names of clients or just their IP addresses
# e.g., www.apache.org (on) or 204.62.129.132 (off).
# The default is off because it'd be overall better for the net if people
# had to knowingly turn this feature on, since enabling it means that
# each client request will result in AT LEAST one lookup request to the
# nameserver.
#
HostnameLookups Off

# ErrorLog: The location of the error log file.
# If you do not specify an ErrorLog directive within a <VirtualHost>
# container, error messages relating to that virtual host will be
# logged here.  If you *do* define an error logfile for a <VirtualHost>
# container, that host's errors will be logged there and not here.
#
ErrorLog ${APACHE_LOG_DIR}/error.log

#
# LogLevel: Control the severity of messages logged to the error_log.
# Available values: trace8, ..., trace1, debug, info, notice, warn,
# error, crit, alert, emerg.
# It is also possible to configure the log level for particular modules, e.g.
# "LogLevel info ssl:warn"
#
LogLevel warn

# Include module configuration:
IncludeOptional mods-enabled/*.load
IncludeOptional mods-enabled/*.conf

# Include list of ports to listen on
Include ports.conf


# Sets the default security model of the Apache2 HTTPD server. It does
# not allow access to the root filesystem outside of /usr/share and /var/www.
# The former is used by web applications packaged in Debian,
# the latter may be used for local directories served by the web server. If
# your system is serving content from a sub-directory in /srv you must allow
# access here, or in any related virtual host.
<Directory />
        Options FollowSymLinks
        AllowOverride None
        Require all denied
</Directory>

<Directory /usr/share>
        AllowOverride None
        Require all granted
</Directory>

<Directory /var/www/>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
</Directory>

#<Directory /srv/>
#       Options Indexes FollowSymLinks
#       AllowOverride None
#       Require all granted
#</Directory>




# AccessFileName: The name of the file to look for in each directory
# for additional configuration directives.  See also the AllowOverride
# directive.
#




# AccessFileName: The name of the file to look for in each directory
# for additional configuration directives.  See also the AllowOverride
# directive.
#
AccessFileName .htaccess

#
# The following lines prevent .htaccess and .htpasswd files from being
# viewed by Web clients.
#
<FilesMatch "^\.ht">
        Require all denied
</FilesMatch>


#
# The following directives define some format nicknames for use with
# a CustomLog directive.
#
# These deviate from the Common Log Format definitions in that they use %O
# (the actual bytes sent including headers) instead of %b (the size of the
# requested file), because the latter makes it impossible to detect partial
# requests.
#
# Note that the use of %{X-Forwarded-For}i instead of %h is not recommended.
# Use mod_remoteip instead.
#
LogFormat "%v:%p %h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" vhost_combined
LogFormat "%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%h %l %u %t \"%r\" %>s %O" common
LogFormat "%{Referer}i -> %U" referer
LogFormat "%{User-agent}i" agent

# Include of directories ignores editors' and dpkg's backup files,
# see README.Debian for details.

# Include generic snippets of statements
IncludeOptional conf-enabled/*.conf

# Include the virtual host configurations:
IncludeOptional sites-enabled/*.conf

LoadModule passenger_module /var/lib/gems/1.9.1/gems/passenger-5.0.5/buildout/apache2/mod_passenger.so
<IfModule mod_passenger.c>
  PassengerRoot /var/lib/gems/1.9.1/gems/passenger-5.0.5
  PassengerDefaultRuby /usr/bin/ruby1.9.1
</IfModule>

<VirtualHost *:80>
ServerName [Your staging server IP]
DocumentRoot /var/www/widgetworld/current/public
<Directory /var/www/widgetworld/current/public>
# This relaxes Apache security settings.
AllowOverride all
# MultiViews must be turned off.
Options -MultiViews
</Directory>
</VirtualHost>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
```

Then add this to your recipe/default.rb file

recipes/app.rb
```bash
  template '/etc/apache2/apache2.conf' do
    source 'app-apache2.conf.erb'
  end
```

Now converge

```bash
  vagrant@workshop $ kitchen converge app-ubuntu-14-04-x64
```

And verify that the tests pass:

```bash
  vagrant@workshop $ kitchen verify app-ubuntu-14-04-x64
```

Huzzah!

Make sure to apply these changes to your testing instance.

```bash
  vagrant@workshop $ knife solo cook root@[testing_node_ip_address]
```

Now let's look at the IP of your staging instance in your favorite browser:

What a minute...we still see that custom page.  What gives?

Turns out, anytime we add a new site to our Apache config, we need to restart the web server.  Let's do that now, adding it to our app recipe.

recipes/app.rb
```bash
  service 'apache2' do
    action [:restart]
  end
```

Now refresh the page in your browser:

Another error???  At least it's a different one, this time.

```bash
  Incomplete response received from application
```

Well...that's not exactly helpful.  Let's do some troubleshooting. SSH into your staging VM:

```bash
  ssh deploy@[your staging instance IP address]
```

A great place to look for errors when you're running Apache is the Apache logs.  Let's tail this log (meaning we will watch the log be generated in real time).

```bash
  deploy@staging $ sudo tail -f /var/log/error.log
```

And let's reload the page in our browser, then take a look back at the console.

Aha!  There's the culprit!

```bash
  App 30307 stderr: [ 2015-03-30 16:47:25.7163 30388/0x000000020823a0(Worker 1) utils.rb:85 ]: *** Exception RuntimeError in Rack application object (Missing `secret_key_base` for 'production' environment, set this value in `config/secrets.yml`) (process 30388, thread 0x000000020823a0(Worker 1)):
```

Remember that secrets.yml file we created?  Now we we need to actually populate it with something.

## Configuring the secrets environmental variable

There's one more environmental variable we need to configure.  Rails 4 introduced the concept of a secrets file.  For more info, check out [this blog post](http://richonrails.com/articles/the-rails-4-1-secrets-yml-file).

Still on your staging instance, open up the /var/www/widgetworld/shared/config/secrets.yml file and add this content:

/var/www/widgetworld/shared/config/secrets.yml
```bash
  # Be sure to restart your server when you modify this file.

  # Your secret key is used for verifying the integrity of signed cookies.
  # If you change this key, all old signed cookies will become invalid!

  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you'll be exposed to dictionary attacks.
  # You can use `rake secret` to generate a secure secret key.

  # Make sure the secrets in this file are kept private
  # if you're sharing your code publicly.

  development:
    secret_key_base: 7ddf23906edc95aed228a016bf57ceda80901d9b0a8d58a5798a54fa5aa4e8509425ff7df5d63f65a393cc27f1ebd4820ff18d5c9d3d753d38037bb9287d9037

  test:
    secret_key_base: 5c565a66bd249c306d5b399086b238fe506fba9a7dc1779459fcc2239fd784b8fa156f64fbb3a0b7ed82bc4fb302bd6fc7dec79976ffc5c9abde95bd21c5a3ba

  # Do not keep production secrets in the repository,
  # instead read values from the environment.
    production:
      secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
```

See this content at the bottom?

```bash
  # Do not keep production secrets in the repository,
  # instead read values from the environment.
    production:
      secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
```

We need to add another couple of lines to this file to use it in a staging environment.  Alter the last part of the file so it looks like this:

```bash
  # Do not keep production secrets in the repository,
  # instead read values from the environment.
    production:
      secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
    staging:
      secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
```


We need to configure that environmental variable.  For the sake of time, we're going to do this one manually, though it would be ideal to incorporate this into our Chef recipe.

Change directories into your current widgetworld directory.

```bash
  deploy@staging $ cd /var/www/widgetworld/current
```

Then run this command to generate your secret key base:

```bash
  deploy@staging $ RAILS_ENV=staging rake secret
```

Now open up the deploy user's bash profile:
```bash
  deploy@staging $ vim ~/.bash_profile
```

And add this content:
```bash
  export SECRET_KEY_BASE=[code you just generated]
```

You can then make sure this variable is set correctly by running

```bash
  deploy@staging $ echo $SECRET_KEY_BASE
```

Then source the bash profile:

```bash
  deploy@staging $ source ~/.bash_profile
```

Now restart Apache to make sure Rails loads this environmental variable:

```bash
  deploy@staging $ sudo service apache2 restart
```

And you should see a page that's ready to list some widgets!

