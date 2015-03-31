# Creating a Production Instance

Now let's create an actual production instance, one that we will direct the users of our product to use.

This is very similar to creating our test server.

```bash
    vagrant@workshop $ knife digital_ocean droplet create --server-name production-vm-group#{group number}.vm.io --image ubuntu-14-04-x64 --location sfo1 --size 1gb --ssh-keys #{key num provided by instructors}
```

Take note of the IP address returned in the output and make sure to pass it on to each of your group members.

You should eventually see output that looks similar to this:

```bash
  Waiting for IPv4-Addressdone
  IPv4 address is: 192.241.201.66
  Waiting for sshd:done
  192.241.201.66
```

Now we need to get Chef on this production server.  This is going to take a little bit of refactoring to make our cookbook usable by both of our environments.

## Refactoring

First, a bit of refactoring.  Open up your template/default/app-apache2.conf file.

See how we hard coded the IP address into it?  This will make it not work on our production VM.  Let's refactor this.

Change this line:

```bash
  ServerName 192.241.201.66
```

To this line:

```bash
  ServerName <%= node["ip_address"] %>
```

And we'll set that node attribute next

## Node Config

Now let's define another json file, this one for the ip address of our production server.

```bash
    vagrant@workshop $ touch nodes/[your_production_nodes_ip_address].json
```

Now open up the json file and the add this content to run each of the recipes in the cookbook.

```bash
  {
    "ip_address": [production instance ip address]
    "run_list": [
      "recipe[my_web_server_cookbook::default]",
      "recipe[my_web_server_cookbook::swap_memory]",
      "recipe[my_web_server_cookbook::passenger]",
      "recipe[my_web_server_cookbook::ruby]",
      "recipe[my_web_server_cookbook::postgresql]",
      "recipe[my_web_server_cookbook::user]",
      "recipe[my_web_server_cookbook::app]"
      ],
  }
```

## Bootstrapping your node

Now bootstrap your node with chef:
```bash
    vagrant@workshop $ knife solo bootstrap root@#{IP ADDRESS FOR NODE}
```

And check out that IP address in your browser.  You should see your custom apache page!

Now the steps we run involving Capistrano are largely the same for our testing instance.

Go back to your WidgetWorld application:

```bash
    vagrant@workshop $ cd ~/widgetworld
```

And open up a deploy config for your production environment with your preferred editor.

```bash
    vagrant@workshop $ vim config/deploy/production.rb
```

Uncomment and change these lines:

```bash
   role :app, %w{deploy@example.com}, my_property: :my_value
   role :web, %w{user1@primary.com user2@additional.com}, other_property: :other_value
   role :db,  %w{deploy@example.com}
```

To this

(Make sure to substitute the ip address for your PRODUCTION node)

```bash
  role :app, %w{deploy@[ip_address]}
  role :web, %w{deploy@[ip_address]}
  role :db,  %w{deploy@[ip_address]}
```

And uncomment and change this line

```bash
  server 'example.com', user: 'deploy', roles: %w{app db web}
```

To this:

(Make sure to substitute the ip address for your PRODUCTION node)

```bash
  server '[ip_address]', user: 'deploy', roles: %w{web app}
```

Now let's check whether our application is ready to deploy to testing.  Run this command:

```bash
    vagrant@workshop $ cap production deploy:check
```

This time it shouldn't prompt for a password because our SSH key is already on the node.

It will fail due to the missing database file.

```bash
  ERROR linked file /var/www/widgetworld/shared/config/database.yml does not exist
```

Capistrano expects to find a file that isn't there.  Let's get this taken care of.

[For the sake of time, we're not adding this file into our Chef cookbook.  However, extra credit points to any student who figures out how to!)

SSH into your production instance.

```bash
  ssh deploy@#{ip address of your production instance}
```

Create and open this file on your VM.
```bash
   deploy@production  vim /var/www/widgetworld/shared/config/database.yml
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
# To create additional roles in postgres see `  vagrant@workshop $ createuser --help`.
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

# Schema search path. The server defaults to   vagrant@workshop $user,public
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

production:
  <<: *default
  database: widgetworld_production
  username: deploy
  password: <%= ENV['WIDGETWORLD_DATABASE_PASSWORD'] %>
```

Then save and close the file.

Now let's set that environment variable.  On your testing VM, run this command:

```bash
     deploy@production $ export WIDGETWORLD_DATABASE_PASSWORD=[password you used in your chef recipe for the deploy user to login to postgres]
```

Now let's just create a file at /var/www/widgetworld/shared/secrets.yml.  We'll add content to it in a little bit.

```bash
    deploy@production $ touch /var/www/widgetworld/shared/config/secrets.yml
```

Now go ahead and exit out of your VM.

Back on your development box, make sure you're in the widgetworld directory.

```bash
    vagrant@workshop $ cd ~/widgetworld
```

Then run the deploy check one more time.

```bash
    vagrant@workshop $ cap production deploy:check
```

If it does not return an error and exits with a line similar to:

```bash
  DEBUG [7f34dcb9] Finished in 0.004 seconds with exit status 0 (successful).
```

Then we're ready to deploy!

Deploy with

```bash
   vagrant@workshop $ cap production deploy
```

Whoops, looks like it needs bundler installed

Then ssh back into your VM (this time as the DEPLOY user, not root)

```bash
  ssh deploy@[your production instance's IP address]
```

And run

Install bundler

```bash
    deploy@production $ sudo gem install bundler
```

Exit out of your production instance and run this command again:

```bash
    vagrant@workshop $ cap production deploy
```

And we have a failure, looks like we need to create our database

First, open up your Capfile, and comment out this line:
```bash
 # require 'capistrano/rails/migrations'
```

Then run your deploy again

```bash
    vagrant@workshop $ cap production deploy
```

And ssh into your production instance:
```bash
    vagrant@workshop $ ssh deploy@[production instance ip]
```

Then change directories to your current widgetworld deploy:

```bash
    vagrant@workshop $ cd /var/www/widgetworld/current
```

Then create your database.  (We're using a very common Ruby/Rails tool called [Rake](https://github.com/ruby/rake)

```bash
    vagrant@workshop $ RAILS_ENV=production rake db:create
```

If you get no output, that means it was a success!

Exit out of your production instance.

Back on your development VM, make sure you're in your widgetworld directory:

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

And it works!

Now let's configure the secrets file.

## Configuring Secrets file

SSH into your production instance:
```bash
    deploy@production $ ssh deploy@[production instance ip]
```

Open up this file with your editor of choice.

```bash
    deploy@production $ vim /var/www/widgetworld/shared/config/secrets.yml
```

And add this content.

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

Save and close the file.

Notice another environment variable?  <%= ENV["SECRET_KEY_BASE"] %>

We need to set this, but first we need to generate a sequence to use as our secret key base. Do this by running this command:

```bash
    deploy@production $ RAILS_ENV=production rake secret
```

This will output a code to use as our secret key base.

Now let's create the environmental variable to store this key. Open up your bash profile in an editor:

```bash
    deploy@production $ vim ~/.bash_profile
```

And add this line to the end of the file

```bash
  export SECRET_KEY_BASE=[code you just generated]
```
Save and close the file, then reload your bash profile

```bash
    deploy@production $ source ~/.bash_profile
```

You can then make sure this variable is set correctly by running

```bash
   deploy@production $ echo $SECRET_KEY_BASE
```

Now restart your Apache service

```bash
   deploy@production $ sudo service apache2 restart
```

## Making Apache aware of our site

We already did this when we refactored our app recipe above.

Now check out the IP address of your Production instance in a browser and you should see the production version of your site!

