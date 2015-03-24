Although Apache works out of the box for some web applications, it does not support Ruby by default.  To serve up a Ruby on Rails application we need an application server in order to make it work.

This tutorial will focus on using [Phusion Passenger](https://www.phusionpassenger.com/).

For an excellent and in depth explanation of the different between a Web Server like Apache and an application server like Passenger, see this fantastic [explanation on Stack Overflow](http://stackoverflow.com/a/4113570).

## Creating a Passenger recipe

Let's generate a new recipe like so:

```bash
  $ chef generate recipe passenger
```

Now we need to create the directory where our server specs will live:

```bash
  $ mkdir -p test/integration/passenger/serverspec
```

And create the test file

```bash
  $ touch test/integration/passenger/serverspec/passenger_spec.rb
```

And we need to be able to access a spec_helper similar to the one living in test/integration/default/serverspec.  In this case, let's copy that one into our new integration test directory.

```bash
  $ cp test/integration/default/serverspec/spec_helper.rb test/integration/passenger/serverspec
```

## Installing the Passenger gem

Were we installing Passenger by hand, we would run this command to install it through Ruby Gems (a very commonly used repo of Ruby libraries)

```bash
  $ gem install passenger
```

But first, we need to write a test for it.

Open up the test file for the passenger recipe:

```bash
  $ vim test/integration/passenger/serverspec/passenger_spec.rb
```

And add in a test to ensure that the passenger gem is installed:

```bash
  require 'spec_helper'
  describe 'my_web_server_cookbook::passenger' do

    describe command('gem list') do
      its(:stdout) { should match /passenger/ }
    end
  end
```

And add in this new test suite to the .kitchen.yml file.  Open it up:

```bash
  $ vim .kitchen.yml
```

And add in this content:

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
```

Then create the test instance.

```bash
  $ kitchen create passenger-ubuntu-14-04-x64
```

And set it up:

```bash
  $ kitchen setup passenger-ubuntu-14-04-x64
```

Now run these tests:

```bash
  $ kitchen verify passenger-ubuntu-14-04-x64
```

And, as expected, we get a failure.

```bash
1) my_web_server_cookbook::passenger Command "gem list" stdout should match /passenger/
  Failure/Error: its(:stdout) { should match /passenger/ }
  expected "gem-wrappers (1.2.7)\n" to match /passenger/
  Diff:
  @@ -1,2 +1,2 @@
  -/passenger/
  +gem-wrappers (1.2.7)

  /bin/sh -c gem\ list
  gem-wrappers (1.2.7)

  # /tmp/busser/suites/serverspec/passenger_spec.rb:4:in `block (3 levels) in <top (required)>'
```

Now let's add the code to make this test pass.

Open up the recipe file:

```bash
  $ vim recipes/passenger.rb
```

And add in this content:

[TO DO: explain why not using gem package]

```bash
  execute 'sudo gem install passenger' do
    command "sudo gem install passenger"
    action :run
  end
```

Then apply the Chef changes to your test instance:

```bash
  $ kitchen converge passenger-ubuntu-14-04-x64
```

Whoops, looks like we got an error.

```bash
  Mixlib::ShellOut::ShellCommandFailed
  ------------------------------------
  Expected process to exit with [0], but received '1'
  ---- Begin output of sudo gem install passenger ----
  STDOUT:
  STDERR: sudo: gem: command not found
```

The gem command needs the Ruby packages installed in order to work.  Let's include our Ruby recipe.  Add this to the top of your recipe file:

```bash
  include_recipe 'my_web_server_cookbook::ruby'
```

Then apply this change

```bash
  $ kitchen converge passenger-ubuntu-14-04-x64
```

And run the tests again:

```bash
  $ kitchen verify passenger-ubuntu-14-04-x64
```

And they pass!

## Installing Passenger dependencies

Passenger requires several packages to work with Apache.

```bash
  apache2-dev, ruby-dev, libapr1-dev, libaprutil1-dev
```

Let's add in tests for each of these packages.

Open up the test file:

```bash
  $ vim test/integration/passenger/serverspec/passenger_spec.rb
```

And add in the following content:

```bash
    describe package('apache2-dev') do
      it { should be_installed }
    end

    describe package('ruby-dev') do
      it { should be_installed }
    end

    describe package('libapr1-dev') do
      it { should be_installed }
    end

    describe package('libaprutil1-dev') do
      it { should be_installed }
    end
```

Then save and close the file and run the tests.

```bash
  $ kitchen verify passenger-ubuntu-14-04-x64
```

And they should fail.

Open up your recipe file.

```bash
  $ vim recipes/passenger.rb
```

And add in this content:

```bash
  package 'apache2-dev'

  package 'ruby-dev'

  package 'libapr1-dev'

  package 'libaprutil1-dev'
```

Save and close the file.  Then apply the Chef changes to your test instance:

```bash
  $ kitchen converge passenger-ubuntu-14-04-x64
```

And run the tests:

```bash
  $ kitchen verify passenger-ubuntu-14-04-x64
```

And they should pass.

## Configuring Passenger to work with Apache

Now let's install the module which will allow passenger to work with Apache

### Installing more swap memory

In order for passenger to work, we need some additional RAM freed up than is configured by default.  We do this through swapping memory.

If you're interested, you can find more (information about swapping and memory usage here)[https://www.digitalocean.com/community/tutorials/how-to-add-swap-on-ubuntu-12-04]

Add this to your test file:

```bash
describe 'my_web_server_cookbook::passenger' do

  describe command('gem list') do
    its(:stdout) { should match /passenger/ }
  end

  describe package('apache2-dev') do
    it { should be_installed }
  end

  describe package('ruby-dev') do
    it { should be_installed }
  end

  describe package('libapr1-dev') do
    it { should be_installed }
  end

  describe package('libaprutil1-dev') do
    it { should be_installed }
  end

  describe command('swapon -s') do
    its(:stdout) { should match /\/swap\s+file\s/ }
  end
end
```

Add this to your recipe file:

```bash
  execute 'create swap file' do
    command "sudo dd if=/dev/zero of=/swap bs=1M count=1024"
    action :run
  end

  execute 'create a linux swap area' do
    command "sudo mkswap /swap"
    action :run
  end

  execute 'activate the swap file' do
    command "sudo swapon /swap"
    action :run
  end
```

Save and close the file.

Now run converge.

```bash
  $ kitchen converge passenger-ubuntu-14-04-x64
```

And run the tests:

```bash
  $ kitchen verify passenger-ubuntu-14-04-x64
```

And they should pass!

But...there's still a problem.  Trying converging again.

```bash
  $ kitchen converge passenger-ubuntu-14-04-x64
```

And we receive this error:

```bash
  Mixlib::ShellOut::ShellCommandFailed
  ------------------------------------
  Expected process to exit with [0], but received '1'
  ---- Begin output of sudo dd if=/dev/zero of=/swap bs=1M count=1024 ----
  STDOUT:
  STDERR: dd: failed to open ‘/swap’: Text file busy
  ---- End output of sudo dd if=/dev/zero of=/swap bs=1M count=1024 ----
  Ran sudo dd if=/dev/zero of=/swap bs=1M count=1024 returned 1
```

Looks like it errors out if we attempt to create the swap file twice.  Let's add a line to the passenger recipe to prevent this from happening.

```bash
  execute "sudo dd if=/dev/zero of=/swap bs=1M count=1024" do
    action :run
    not_if { ::File.exists?("/swap")}
  end
```

And now converge again:

```bash
  $ kitchen converge passenger-ubuntu-14-04-x64
```

And run the tests:

```bash
  $ kitchen verify passenger-ubuntu-14-04-x64
```

And they should pass!

### Installing the Apache Passenger module

Now it's time to get Passenger up and running with Apache. To do this, we need to install the passenger-install-apache2-module.  First, let's add a test.

When the module is installed, there's a mod_passenger.so file on the server.  Our test will check that this is the case.

```bash
  describe file('/var/lib/gems/1.9.1/gems/passenger-5.0.4/buildout/apache2/mod_passenger.so') do
    it { should be_file }
  end
```

And run the tests:

```bash
  $ kitchen verify passenger-ubuntu-14-04-x64
```

And, as expected, it fails.

Now add this to your recipe file:

```bash
  execute 'passenger-install-apache2-module' do
    command "sudo passenger-install-apache2-module --auto"
    action :run
  end
```

And converge and run the tests again.  (This converge will take awhile to run, the module takes some time to install).

```bash
  $ kitchen converge passenger-ubuntu-14-04-x64
```

Now run the tests.

```bash
  $ kitchen verify passenger-ubuntu-14-04-x64
```

And they should pass!  One final thing, we don't want to install the module if it's already installed, at the very least it's an immense amount of unnecessary time to install.

Add one line to you recipe to prevent running the module install when it has already been run.

```bash
  execute 'passenger-install-apache2-module' do
    command "sudo passenger-install-apache2-module --auto"
    action :run
    not_if { ::File.exists?("/var/lib/gems/1.9.1/gems/passenger-5.0.5/buildout/apache2/mod_passenger.so")}
  end
```

## Creating the Apache Config file

Now it's time to create an apache config file template.  Let's generate a template.

You need to run the generate template command from your my_web_server_chef_repo directory

```bash
  $ cd ~/my_web_server_chef_repo
```

```bash
  $ chef generate template cookbooks/my_web_server_cookbook apache2.conf
```

Now change directories back to your cookbook directory:

```bash
  $ cd cookbooks/my_web_server_cookbook
```

Then add in a couple of tests for the apache2 conf template to test/integration/passenger/serverspec/passenger_spec.rb

```bash
  describe file('/etc/apache2/apache2.conf') do
    it { should be_file }

    its(:content) { should match /LoadModule passenger_module \/var\/lib\/gems\/1.9.1\/gems\/passenger-5\.0\.5\/buildout\/apache2\/mod_passenger.so/ }
  end
```

Then, run the tests.

```bash
  $ kitchen verify passenger-ubuntu-14-04-x64
```

As expected, it fails.

Let's fill in the config file template.

```bash
  $ vim templates/default/apache2.conf.erb
```

With this content, including the lines we are expecting:

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

LoadModule passenger_module /var/lib/gems/1.9.1/gems/passenger-5.0.4/buildout/apache2/mod_passenger.so
<IfModule mod_passenger.c>
  PassengerRoot /var/lib/gems/1.9.1/gems/passenger-5.0.4
  PassengerDefaultRuby /usr/bin/ruby1.9.1
</IfModule>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
```

Now call this template from you passenger recipe file:

```bash
template '/etc/apache2/apache2.conf' do
  source 'apache2.conf.erb'
end
```

Then converge

```bash
  $ kitchen converge passenger-ubuntu-14-04-x64
```

And run your tests

```bash
  $ kitchen verify passenger-ubuntu-14-04-x64
```

And they pass!
