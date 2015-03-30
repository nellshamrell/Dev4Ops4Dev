We're going to use an automated deployment tool called [Capistrano](http://capistranorb.com/) to both do our initial deploy and future deploys.  Capistrano is frequently used with Ruby on Rails applications (it is written in Ruby) but can be used with other languages as well.

# Setting up the Rails application
```bash
  $ cd widgetworld
```

Open up the Gemfile

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

(It was already installed when you ran "sudo gem install pg -v '0.17.1'")

Then rerun:

```bash
  $ bundle
```

# Installing and Configuring Capistrano

There is also some special additional installation for capistrano.  Run this command, which will add some additional Capistrano config files.

```bash
  $ cap install
```

Next, open your Capfile in your favorite editor

```bash
   $ vim Capfile
```

Uncomment these lines

```bash
  # require 'capistrano/rvm'
  # require 'capistrano/bundler'
  # require 'capistrano/rails/migrations'
```

So it looks like this

```bash
  require 'capistrano/rvm'
  require 'capistrano/bundler'
  require 'capistrano/rails/migrations'
```

 Next, open up the config/deploy.rb file with your favorite text editor

 ```bash
  $ vi config/deploy.rb
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
  $ cd ~/my_web_server_chef_repo/cookbooks/my_web_server_cookbook
```

Let's create a new recipe, this one specifically for the app.

```bash
  $ chef generate recipe app
```

Now we need to create the directory where our server specs will live:

```bash
  $ mkdir -p test/integration/app/serverspec
```

And create the test file

```bash
  $ touch test/integration/app/serverspec/app_spec.rb
```

And we need to be able to access a spec_helper similar to the one living in test/integration/default/serverspec.  In this case, let's copy that one into our new integration test directory.

```bash
  $ cp test/integration/default/serverspec/spec_helper.rb test/integration/app/serverspec
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
  $ vim .kitchen.yml
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
  $ kitchen create app-ubuntu-14-04-x64
```

And then set it up with Chef:

```bash
  $ kitchen setup app-ubuntu-14-04-x64
```

Now, run the tests:

```bash
  $ kitchen verify app-ubuntu-14-04-x64
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
  $ kitchen converge app-ubuntu-14-04-x64
```

And run the tests again

```bash
  $ kitchen verify app-ubuntu-14-04-x64
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
  $ knife solo cook root@[your staging instance ip]
```

## Setting Capistrano roles

Now change back to your widgetworld directory

```bash
  $ cd ~/widgetworld
```

Take a look at the various deploy configs:

```bash
  $ ls config/deploy
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
  $ cap staging deploy:check
```

Whoops, looks like it's prompting for a password.  This is because our ssh key is not on the testing instance for the deploy user.  Let's get that fixed.

## Adding your SSH Key

Change directories back to your chef cookbook.

```bash
  $ cd ~/my_web_server_chef_repo/cookbooks/my_web_server_cookbook/
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
  $ kitchen verify user-ubuntu-14-04-x64
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
  $ kitchen converge user-ubuntu-14-04-x64
```

```bash
  $ kitchen verify user-ubuntu-14-04-x64
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
  $ kitchen verify user-ubuntu-14-04-x64
```

And watch them fail.

Now let's make them pass.  We need a template with the SSH key in it.

Change directories back to your Chef repo directory

```bash
  $ cd ~/my_web_server_chef_repo
```

And generate the template.

```bash
  $ chef generate template cookbooks/my_web_server_cookbook ssh_key
```

Now change directories back to your cookbook directory:

```bash
  $ cd cookbooks/my_web_server_cookbook
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
  $ kitchen converge user-ubuntu-14-04-x64
```

```bash
  $ kitchen verify user-ubuntu-14-04-x64
```

And they should pass!

Now let's apply these changes to our testing node.  Run this command:

```bash
  $ knife solo cook root@[testing_node_ip_address]
```

## Setting environment variables

Rails 4 requires that two environment variables be set for our database.yml and secrets.yml config files.

Let's take a look at this.

Change to your widget world directory and take a look at very bottome of the file at config/database.yml

```bash
production:
  <<: *default
  database: widgetworld_production
  username: deploy
  password: <%= ENV['WIDGETWORLD_DATABASE_PASSWORD'] %>
```

That's the configuration for the production database.  First, let's copy this, then modify it slightly so we have configs for both staging and production databases.


```bash
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

We need to set this environmental variable: WIDGETWORLD_DATABASE_PASSWORD.  We COULD do this manually, but let's try capturing it in our Chef recipe.

Change back to your chef repo:

```bash
  $ cd ~/my_web_server_chef_repo
```

We're going to add this environment variable to the deploy user's .bash_profile.  To do this, we need to generate a template.

```bash
  $ chef generate template cookbooks/my_web_server_cookbook bash_profile
```

Now change directories back to your cookbook directory.

```bash
  $ cd cookbooks/my_web_server_cookbook
```

## Configuring your database environment variable
And let's first create a test:

Open up your test file with the editor of your choice:

```bash
  $ vim test/integration/app/serverspec/app_spec.rb
```

And add this content:

```bash
  describe command('cat /home/deploy/.bash_profile') do
    it { should be_file }
    its(:content) { should match /export WIDGETWORLD_DATABASE_PASSWORD=abc123/ }
  end
```

Notice that we provided a sample value for SECRET_KEY_BASE?  Now let's add this to our .kitchen.yml so our tests can access this value:

Open up .kitchen.yml, then add in this content as an attribute in our app suite.

.kitchen.yml
```bash
- name: app
  run_list:
    - recipe[my_web_server_cookbook::app]
  attributes:
    - [FILL IN ATTRIBUTE SYNTAX HERE]
```

Now let's run our tests:

```bash
  $ kitchen verify app-ubuntu-14-04-x64
```

And they should fail.  Now we'll make them pass.

Open up your template file and add this content:

templates/default/bash_profile.erb
```bash
  export WIDGETWORLD_DATABASE_PASSWORD=<%= node["postgres_password"]
```

Now open up your app recipe file:
```bash
  $ vim recipes/app.rb
```

And add this content to call the bash profile template, then source the bash profile file to load the environment variable.

Notice the "." before bash_profile!

```bash
template '/home/deploy/.bash_profile' do
  source 'bash_profile.erb'
end

execute 'source bash profile' do
  command "source ~/home/deploy/.bash_profile"
  action :run
end
```

Now run your tests again:

```bash
  $ kitchen verify app-ubuntu-14-04-x64
```

And they should pass!

Now we need to add this to our node configuration. Open up that json file and add in this content:

nodes/[your_staging_instance_ip_address].json

```bash
  {
    "postgres_password": [generate a random password for your db]
    "run_list": [
      "recipe[my_web_server_cookbook::app]"
    ]
  }
```

Now let's apply these changes to our staging node.

```bash
  $ knife solo cook root@[testing_node_ip_address]
```

## Deploying again

Let's switch back to the widgetworld directory.

```bash
  $ cd ~/widgetworld
```

And try the deploy check again.

```bash
  $ cap staging deploy:check
```

If you receive git error, do this:

```bash
  $ ssh-add ~/.ssh/id_rsa
```

Then run the deploy check again.

```bash
  $ cap staging deploy:check
```

If it does not return an error and exits with a line similar to:

```bash
  DEBUG [7f34dcb9] Finished in 0.004 seconds with exit status 0 (successful).
```

Then we're ready to deploy for real!

## Deploying with Capistrano

Deploy with

```bash
 $ cap staging deploy
```

## Configuring the secrets environmental variable

There's one more environmental variable we need to configure.  Rails 4 introduced the concept of a secrets file.  For more info, check out (this blog post)[http://richonrails.com/articles/the-rails-4-1-secrets-yml-file].

Take a look at this file in your widgetworld directory

```bash
 $ cat ~/widgetworld/config/secrets.yml
```

See this content at the bottom?

```bash
  # Do not keep production secrets in the repository,
  # instead read values from the environment.
    production:
      secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
```

We need to configure that environmental variable.  For the sake of time, we're going to do this one manually, though it would be ideal to incorporate this into our Chef recipe.

SSH into your staging node like this (Notice that you're sshing as the DEPLOY user, not the root user)

```bash
 $ ssh deploy@[your staging instance ip address]
```

And change directories into your current widgetworld directory.

```bash
 $ cd /var/www/widgetworld/current
```

Then run this command to generate your secret key base:

```bash
  $ RAILS_ENV=staging rake secret
```

And run this command to set the environmental variable.

```bash
  export SECRET_KEY_BASE=[code you just generated]
```

You can then make sure this variable is set correctly by running

```bash
  $ echo $SECRET_KEY_BASE
```
