# Setting up the Rails application
cd back to home directory of VM

```bash
  $ cd
```

Clone Widget World application

```bash
  $ git clone git@github.com:nellshamrell/widgetworld.git
```

```bash
  $ cd widgetworld
```

open Gemfile

```bash
  $ vim Gemfile
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
  $ bundle
```

If you receive this error:

```bash
  Can't find the 'libpq-fe.h header
  *** extconf.rb failed ***
  Could not create Makefile due to some reason, probably lack of necessary
  libraries and/or headers.
```

Run this on your development VM:

```bash
  $ sudo apt-get install postgresql-client libpq5 libpq-dev
  $ sudo gem install pg -v '0.17.1'
```

Then rerun:

```bash
  $ bundle
```

If you continue to get the same error, comment out the pg gem line in your Gemfile

```bash
  #gem 'pg'
```

Then rerun:

```bash
  $ bundle
```

# Installing and Configuring Capistrano

There is also some special additional installation for capistrano.  Run this command, which will add some additional Capistrano config files.
```bash
(Local) $ cap install
```

Next, open your Capfile in your favorite editor

```bash
(Local) $ vi Capfile
```

Uncomment this line

```bash
# require 'capistrano/rvm'
```

So it looks like this

```bash
 require 'capistrano/rvm'
 ```

 Later on we'll be storing our database credentials (including password) in config/database.yml.  To avoid accidentally committing this to our potentially public repo, let's first make a copy of the file to serve as an example

 ```bash
 (Local) $ cp config/database.yml config/database_example.yml
 ```

 The open up your .gitignore file with your favorite editor

 ```bash
 (Local) $ vi .gitignore
 ```

 And add this line to the file

 ```bash
 config/database.yml
 ```

 This will keep the database.yml file out of any git commits, histories, or repos.

 While we're at it, let's also add config/secrets.yml.  Widget World is a Rails 4 application and Rails 4 added the secrets configuration file to contain credentials.  This is not something we want possible exposed to the world in source control, so add this line to your .gitignore file, then save and close the file.

 ```bash
 config/secrets.yml
 ```

 Next, open up the config/deploy.rb file with your favorite text editor

 ```bash
 (Local) $ vi config/deploy.rb
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
  set :linked_files, fetch(:linked_files, []).push('config/database.yml')
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

```bash
include_recipe 'my_web_server_cookbook::default'
include_recipe 'my_web_server_cookbook::deploy_user'

execute 'change owner and group' do
  command "sudo chown deploy:deploy /var/www"
  action :run
end
```
Adding User databag

Install users community cookbook

```bash
  $ knife cookbook site install users
```

Create recipe

```bash
  $ chef generate recipe user
```

test/integration/deploy_user/serverspec/deploy_user_spec.rb
```bash
  require 'spec_helper'
  describe 'my_web_server_cookbook::user' do
    describe file('/home/deploy/.ssh') do
      it { should be_directory }
    end

    describe file('/home/deploy/.ssh/authorized_keys') do
      it { should be_file }

      its(:content) { should match /ssh-rsa.+nellshamrell@gmail.com/ }
    end

  end
```

recipes/deploy_user.rb
```bash
  include_recipe 'my_web_server_cookbook::deploy_user'

  execute 'create .ssh directory' do
    command "sudo mkdir /home/deploy/.ssh"
    action :run
    not_if { ::File.exists?("/home/deploy/.ssh")}
  end

  template '/home/deploy/.ssh/authorized_keys' do
    source 'ssh_key.erb'
  end
```

templates/default/ssh_key.erb

```bash
  insert ssh key
```

# Setting Capistrano roles

Finally, we need to make some changes to config/deploy/production.rb (back in your widget world directory)

Change these lines

```bash
  role :app, %w{deploy@example.com}
  role :web, %w{deploy@example.com}
  role :db,  %w{deploy@example.com}
```

To this

```bash
  role :app, %w{deploy@#{ip_address}}
  role :web, %w{deploy@#{ip_address}}
  role :db,  %w{deploy@#{ip_address}}
```

And change this line

```bash
  server 'example.com', user: 'deploy', roles: %w{web app}, my_property: :my_value
```

To this:

```bash
  server '#{ip_address}', user: 'deploy', roles: %w{web app}, my_property: :my_value
```
To check whether the application is ready to be deployed with capistrano, run

```bash
  $ cap production deploy:check
```

If receive git error, do this:
```bash
  $ ssh-add ~/.ssh/id_rsa
```

It will likely error out the first time, telling you that /var/www/widgetworld/shared/config/database.yml does not exist on the VM.  To fix this:

[TO DO: Move into Chef recipe]

Create and open this file on your VM.
```bash
(VM) $ vim /var/www/widgetworld/shared/config/database.yml
```

Then copy the contents from config/database.yml in the widgetworld directory on your local machine, then paste them into this file on your VM.

You'll need to make some changes under the 'production' section of database.yml on your VM.

Change the username to "deploy" and the password to whatever password you set for the deploy postgres user when you created it.

It should look like this:

```bash
production:
  <<: *default
  database: widgetworld_production
  username: deploy
  password: #{password you set for the deploy user of postgres}
```

Save and close the file.

[TO DO: Add /var/www/widgetworld/shared/config/secrets.yml]
Run the check again.
```bash
(Local) $ cap production deploy:check
```

If it does not return an error and exits with a line similar to:

```bash
DEBUG [7f34dcb9] Finished in 0.004 seconds with exit status 0 (successful).
```

Then we're ready to deploy!

## 2. Deploying with Capistrano

Deploy with

```bash
(Local) $ cap production deploy
```

Now, navigate to the site's folder on your VM.

```bash
(VM) $ cd /var/www/widgetworld/current
```

Install bundler

```bash
(VM) $ sudo gem install bundler
```

And run bundler in this directory.

```bash
(VM) $ bundle
```

  Next, create the database for your Rails application and run migrations with these commands
  ```bash
  (VM) $ RAILS_ENV=production rake db:create
  (VM) $ RAILS_ENV=production rake db:migrate
  ```

  (NOTE: This section of the tutorial was inspired by this [Stack Overflow Response](http://stackoverflow.com/a/26172408)


  Finally, we need to make Apache aware of our new site.  Add this to
  /etc/apache2/apache2.conf in your VM

  ```bash
  <VirtualHost *:80>
  ServerName 192.168.33.10
  DocumentRoot /var/www/widgetworld/current/public
  <Directory /var/www/widgetworld/current/public>
  # This relaxes Apache security settings.
  AllowOverride all
  # MultiViews must be turned off.
  Options -MultiViews
  </Directory>
  </VirtualHost>
  ```

  And restart Apache
  ```bash
  (VM) $ sudo service apache2 restart
  ```

  Navigate back to your site in your browser.

  If you receive a passenger error "Could not find a JavaScript runtime", run
  ```bash
  (VM) $ sudo apt-get install nodejs
  ```

  The restart Apache again
  ```bash
  (VM) $ sudo service apache2 restart
  ```

  And congratulations!  You now have a working web server that you have deployed your application to and it works!

