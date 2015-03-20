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




