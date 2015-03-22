

Apache is the main piece of our web server, in fact it's called a "Web Server."  It's what enables communication over networks, which allows our server to connect and be connected to the outside world.

# Install Apache by hand

## Setting up a clean Ubuntu Server

Let's spin up a clean copy of a server running Ubuntu to practice installing Apache. (This is a separate Vagrant box from the development environment)

Create a new directory in your workshop directory, maybe call it "hand_crafted_apache" or something to that effect.

Initiate a Vagrant file with:

```bash
  you@laptop $vagrant init workshop
```

Then spin up the Vagrant VM.  This time we'll set a flag to give it a different name internally, so we can keep our prompts clear.

```bash
  you@laptop $ WORKSHOP_HOSTNAME=apache-test vagrant up
```

Then SSH into the VM, using either terminal ssh (Linux, MacOS) or PuTTY SSH (windows)

```bash
  you@laptop $ vagrant ssh
```

## Installing the Apache package

Run:

```bash
  vagrant apache-test $ sudo apt-get install apache2
```

Once this is complete, let's verify that Apache is working on this VM.  Run this command:

```bash
  vagrant apache-test $ wget -qO- 127.0.0.1
```

If Apache is installed correctly, the command line will output an html document which includes the words "It works!"

Let's make that home page a little more interesting by adding a custom one.

Open up the file at /var/www/html/ using your preferred text editor (vim, emacs, joe, and nano are available) (note that you need to use sudo for this one).

```bash
  vagrant apache-test $ sudo vim /var/www/html/index.html
```

Delete all the content in the file, then add in just this line.

```bash
  <h1>I AM A CUSTOM PAGE</h1>
```

Now run the wget command again:

```bash
  vagrant apache-test $ wget -qO- 127.0.0.1
```

And you should see this output:

```bash
  vagrant apache-test $ <h1>I AM A CUSTOM PAGE</h1>
```

Now we are done with this VM.  Go ahead and exit out of it, then run:

```bash
  vagrant apache-test $ vagrant destroy
```
Return back to your development VM.

# Install Apache with Chef

Installing Apache by hand may work well on one or two servers - but imagine a fleet of hundreds or thousands of servers.  Installing Apache on all of them by hand, then keeping them updated and synced by hand, would be unmanageable.  Fortunately, as we are a ChefConf, we can use Chef to capture this installation of Apache in a cookbook and enable us to automate it across rows and rows of servers.

## Creating a Chef Repo for our cookbooks, etc.

First, we need to create a Chef repo of our own.  This will contain all our cookbooks, templates, etc. for our web server.

Make sure you're on your DEVELOPMENT VM and run

```bash
  vagrant@workshop $ chef generate repo my_web_server_chef_repo
```

Then CD into that directory:

```bash
  vagrant@workshop $ cd my_web_server_chef_repo
```

## Creating a Cookbook

Now, let's create an actual cookbook to manage our Apache installs.

```bash
  vagrant@workshop $ chef generate cookbook cookbooks/my_web_server_cookbook
```

Chef automatically generates several files and directories within cookbooks/my_web_server_cookbook.  Let's take a quick look:


```bash
  vagrant@workshop $ ls cookbooks/my_web_server_cookbook
  Berksfile  chefignore  metadata.rb  README.md  recipes  spec  test
```

Let's open up that metadata.rb file.  Use your preferred text editor (here I use vim).

```bash
  vagrant@workshop $ vim cookbooks/my_web_server_cookbook/metadata.rb
```

You should see content similar to this:

```bash
  name             'my_web_server_cookbook'
  maintainer       'The Authors'
  maintainer_email 'you@example.com'
  license          'all_rights'
  description      'Installs/Configures my_web_server_cookbook'
  long_description 'Installs/Configures my_web_server_cookbook'
  version          '0.1.0'
```

Change the maintainer and maintainer values to your name and your email respectively.  Leave the other values as they are for now.

### Creating a recipe to install Apache

Cookbooks always contain recipes and our's is no different.  When we create a cookbook with the chef generate cookbook command, it automatically creates a recipes directory.  Even better, there's already a recipe included called "default.rb".  Open up the default.rb recipe with your favorite text editor (here I use Vim).

```bash
  vagrant@workshop $ vim cookbooks/my_web_server_cookbook/recipes/default.rb
```

And insert the following

```bash
  package 'apache2' # Installs the apache2 package
```

Here we're defining a resource that we expect to find on our servers after running Chef.  This tells Chef to install the apache2 package if it is not already there.

Now save and quit this file.

We haven't applied this recipe to our development environment yet.  Let's verify that apache2 is not installed by typing in this command.

[TO DO: Explain more about dpkg command?]

```bash
  $ dpkg -l apache2
```

You should get back the output

```bash
  dpkg-query: no packages found matching apache2
```

Now let's apply that chef recipe we just created using the "chef-client" command.

[TO DO: Explain more about Chef client?]

```bash
  $ sudo chef-client --local-mode --runlist 'recipe[my_web_server_cookbook]'
```

Take a look at the output, you should see these lines toward the end:

```bash
  Recipe: my_web_server_cookbook::default
    * apt_package[apache2] action install
    - install version 2.4.7-1ubuntu4.4 of package apache2
```
And this line at the very end:

```bash
  Chef Client finished, 1/1 resources updated in 17.974085269 seconds
```

Now run the dkpg command again, checking whether apache2 is installed.

```bash
  $ dpkg -l apache2
```

You should receive output similar to this:

```bash
  Desired=Unknown/Install/Remove/Purge/Hold
  | Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
  |/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
  ||/ Name             Version       Architecture  Description
  +++-================-=============-=============-=====================================
  ii  apache2          2.4.7-1ubuntu amd64         Apache HTTP Server
```

Excellent, the apache2 package is installed on our development box!

Now, let's add in a custom home page.

### Starting and Enabling Apache

It's great that we now have Apache installed, but without it doesn't do us any good unless we start the service that manages it.

[TO DO: Explain what a service is?]

When we installed the apache2 package, the apache2 service was started automatically.  This may not always be the case, however.  Anytime our web server boots or at any time it is running, it should the apache2 service should be running.

For example purposes, let's stop the apache2 service for the moment.

```bash
  $ sudo service apache2 stop
```

Now let's check the status of all services running our our system:

```bash
  $ sudo service --status-all
```

You should see output similar to this:

```bash
  [ + ]  acpid
  [ - ]  apache2
  [ + ]  apparmor
  (etc)
```

Notice that "-" sign on the apache2 line?  That means the service is not running.  Let's enable this through our apache cookbook.

Open up the default recipe in the apache cookbook with your preferred text editor:

```bash
  $ vim cookbooks/my_web_server_cookbook/recipes/default.rb
```

Then add these lines:

```bash
  service 'apache2' do
    action [:start, :enable] # Starts and enables the apache2 service on boot
  end
```

This will check whether the apache2 service is running anytime we do a chef-client run on our web server.  If the service is not running, Chef will start it.

Save and exit the file, then run chef-client.

[============BROKEN=================]
[TODO: For some reason Chef is seeing the service as started, even though we've stopped it and it is not working.  Troubleshoot.]

```bash
  $ sudo chef-client --local-mode --runlist 'recipe[my_web_server_cookbook]'
```

After the run is complete, re-run

```bash
  $ sudo service --status-all
```

You should see output similar to this:

```bash
  [ + ]  acpid
  [ + ]  apache2
  [ + ]  apparmor
  (etc)
```

That plus sign means the service is now running!
[============/BROKEN=================]

## Test Drive Installing Apache with Chef

[TO DO: Intro to TDD]

We're going to re-create the apache2 cookbook we made earlier, but this time using Test Driven Development methodology.  Go ahead and delete the cookbook you created earlier with:

```bash
  $ rm -rf cookbooks/my_web_server_cookbook
```

### Verify Test Kitchen

To Test Drive creating our Apache Chef cookbook, we're going to use a test framework called [Test Kitchen](https://github.com/test-kitchen/test-kitchen).

Test Kitchen is included in the ChefDK you downloaded earlier.  Verify that it is on your system by running:

```bash
  $ kitchen version
```

You should see output similar to:

```bash
  Test Kitchen version 1.3.1
```

### Creating a new cookbook

Now let's create the cookbook again, ChefDK will include all the Test Kitchen templates that we need.

```bash
  $ chef generate cookbook cookbooks/my_web_server_cookbook
```

Open up that metadata.rb file in your my_web_server_cookbook directory.  Use your preferred text editor (here I use vim).

```bash
  $ vim cookbooks/my_web_server_cookbook/metadata.rb
```

You should see content similar to this:

```bash
  name             'my_web_server_cookbook'
  maintainer       'The Authors'
  maintainer_email 'you@example.com'
  license          'all_rights'
  description      'Installs/Configures my_web_server_cookbook'
  long_description 'Installs/Configures my_web_server_cookbook'
  version          '0.1.0'
```

Change the maintainer and maintainer values to your name and your email respectively.  Leave the other values as they are for now.

Test Kitchen specifically uses the name and version attributes.

### Setting up Tesk Kitchen within your cookbook

Change directories to your apache2 cookbook

```bash
  $ cd cookbooks/my_web_server_cookbook
```

List all files and directories, including hidden files

[TO DO: Explain -a flag more?)

```bash
  $ ls -la
```

You should see output similar to this.

```bash
  drwxrwxr-x 6 vagrant vagrant 4096 Mar 10 20:19 .
  drwxrwxr-x 3 vagrant vagrant 4096 Mar 10 18:19 ..
  -rw-rw-r-- 1 vagrant vagrant   47 Mar 10 18:19 Berksfile
  -rw-rw-r-- 1 vagrant vagrant  974 Mar 10 18:19 chefignore
  drwxrwxr-x 7 vagrant vagrant 4096 Mar 10 18:19 .git
  -rw-rw-r-- 1 vagrant vagrant  126 Mar 10 18:19 .gitignore
  -rw-rw-r-- 1 vagrant vagrant  215 Mar 10 20:19 .kitchen.yml
  -rw-rw-r-- 1 vagrant vagrant  270 Mar 10 18:19 metadata.rb
  -rw-rw-r-- 1 vagrant vagrant   64 Mar 10 18:19 README.md
  drwxrwxr-x 2 vagrant vagrant 4096 Mar 10 18:19 recipes
  drwxrwxr-x 3 vagrant vagrant 4096 Mar 10 18:19 spec
  drwxrwxr-x 3 vagrant vagrant 4096 Mar 10 18:19 test
```

Notice that .kitchen.yml file?  This is the configuration file for our test environments.  Test Kitchen spins up an actual VM to run tests in - that way it will have the same behavior as a production system which uses the same cookbook.

Go ahead and open this file with your favorite text editor.

```bash
  $ vim .kitchen.yml
```

It should look like this:

```bash
  driver:
    name: vagrant

  provisioner:
    name: chef_zero

  platforms:
    - name: ubuntu-12.04
    - name: centos-6.5

  suites:
    - name: default
    run_list:
      - recipe[my_web_server_cookbook::default]
    attributes:
```

See those first two lines where we define what driver we want test kitchen to use?  That defines what platform we want the VM test kitchen will spin up to run on.  By default, Test Kitchen will spin up a Vagrant VM and normally this is how I run Test Kitchen.


However, all of us in this workshop are already developing on Vagrant VMs.  Spinning up a VM within a VM is messy at best, fortunately there are other platforms Test Kitchen can use to spin up a VM.  We're going to use Digital Ocean.

### DigitalOcean Setup

We will need to set some environmental variables in your shell that Test Kitchen will use to authenticate to Digital Ocean.  We've done some special things to your Vagrant Box that should make all of this "just work".

Copy the file digitalocean-creds.txt from the USB stick to the directory that contains the Vagrantfile.  Then log out and log back in to your development vm (or re-source your bash profile).

```bash
  vagrant@workshop $ exit
  you@laptop $ vagrant ssh
```

To check for the variables, run:

```bash
  vagrant@workshop $ env | grep DIGITAL
```

You should see two lines.  If you don't, raise your hand.

Now, open up your .kitchen.yml file and modify it so it looks like this:

[TO DO: Explain more what each item in kitchen.yml file is doing]

```bash
---
driver:
  name: digitalocean

provisioner:
  name: chef_zero

platforms:
  - name: ubuntu-14-04-x64
    driver_config:
      region: sfo1
      private_networking: false


suites:
  - name: default
    run_list:
      - recipe[my_web_server_cookbook::default]
    attributes:
```

Save and close the file.

Now run the command:

```bash
  $ kitchen list
```

You should receive output similar to this:

```bash
  Instance             Driver        Provisioner  Last Action
  default-ubuntu-1404  Digitalocean  ChefZero     <Not Created>
```

This means Test Kitchen is now aware there is an environment it needs to run tests against our cookbook in, but it has not yet been created.

### Running Test Kitchen Against Digital Ocean

Let's go ahead and create this instance for Test Kitchen on Digital Ocean:

```bash
  $ kitchen create default-ubuntu-1404
```

This will take a little bit while Digital Ocean spins up the instance and gets it ssh ready.  you should receive this confirmation message within 6-7 minutes:


```bash
  Finished creating <default-ubuntu-1404> (5m15.98s).
  -----> Kitchen is finished. (5m16.34s)
```

Alright, let's run kitchen list again:

```bash
  $ kitchen list
```

You should see output similar to this:

```bash
  Instance             Driver        Provisioner  Last Action
  default-ubuntu-1404  Digitalocean  ChefZero     Created
```

The final thing we need to do is install Chef Client on this instance in order to run our tests.  To do that, run:

```bash
  $ kitchen setup
```

You'll see lots of output.  When it completes, run kitchen list one last time:
```bash
  $ kitchen list
```

Now you'll see this output:
```bash
  Instance             Driver        Provisioner  Last Action
  default-ubuntu-1404  Digitalocean  ChefZero     Set Up
```

And now we're ready to write and run some tests!

### Checking that Test Kitchen can run our code

First, let's make sure that Test Kitchen can run our code.

Open up recipes/default.rb

```bash
  $ vim recipes/default.rb
```

And add this content.

```bash
  log "TEST KITCHEN IS RUNNING MY CODE!!!"
```

Save and close the file.

Now we'll use Test Kitchen to run this code.  To do this, we use the "kitchen converge" command:

```bash
  $ kitchen converge default-ubuntu-1404
```

At some point in the output, you should see this:

```bash
  Recipe: my_web_server_cookbook::default
    * log[TEST KITCHEN IS RUNNING MY CODE!!!] action write
```

Huzzah!  This means Test Kitchen can run our cookbook!

### Creating a Test

One of the benefits of Test Driven Development is that it forces you to clarify exactly what you want your code to do before you run it.  Let's clarify that we want our cookbook to install apache2 with a test.

To do this, we will use something called [ServerSpec].  ServerSpec allows us to write [RSpec](http://rspec.info/) tests (RSpec is a domain specific language used for testing Ruby code).  ServerSpec is automatically included with ChefDK.

Our tests will live in the /test/integration directory of our cookbook.  Go ahead and take a look at the contents of that directory with:

```bash
  $ ls test/integration
```

You'll see a directory called "default."  This is where the specs for our default recipe will live.  Go ahead and take a look inside that directory.

```bash
  $ ls test/integration/default
```

You'll now see a directory called "serverspec."  There are multiple testing languages that can be used with test kitchen and here is where you would provide directories for each language.  We're using serverspec and the serverspec directory is already there, so we're good to go.

Take a look in the serverspec directory:

```bash
  $ ls test/integration/default/serverspec
```

You'll see two files: default_spec.rb and spec_helper.rb.  Open up default_spec.rb:

```bash
  $ vim test/integration/default/serverspec/default_spec.rb
```

And you'll see a placeholder spec that looks like this:

```bash
require 'spec_helper'

describe 'my_web_server_cookbook::default' do

  # Serverspec examples can be found at
  # http://serverspec.org/resource_types.html

  it 'does something' do
    skip 'Replace this with meaningful tests'
  end

end
```

This is a good guide to how our tests will be structured.  We define the cookbook and recipe we're testing in a "describe block", then we write tests for it within that block.  We define individual specs with "it" blocks.

So let's delete that placeholder spec and replace it with a real spec.

```bash
require 'spec_helper'

describe 'my_web_server_cookbook::default' do

  # Serverspec examples can be found at
  # http://serverspec.org/resource_types.html

  describe package('apache2') do
    it { should be_installed }
  end

end
```

Here we're defining a package (apache2), then specifying that it should be installed.

A key factor of Test Driven Development is to write the test first, then run it and make sure it fails before writing the code to make it pass.  This ensures that our test is testing what we think it is.

Let's run 'kitchen list' to make sure that our instance is converged and ready for testing.

```bash
  $ kitchen list
```

You should see:

```bash
  Instance                  Driver        Provisioner  Last Action
  default-ubuntu-14-04-x64  Digitalocean  ChefZero     Converged
```

Now let's run our test.

```bash
  $ kitchen verify
```

whoops - looks like we got an error.  Rather than running tests, then exiting with a test failure, it has errored out when converging.  Converge installs our Chef recipe on our test instance, only after that does it run the tests.

```bash
  >>>>>> Converge failed on instance <default-ubuntu-14-04-x64>.
  >>>>>> Please see .kitchen/logs/default-ubuntu-14-04-x64.log for more details
  >>>>>> ------Exception-------
  >>>>>> Class: Kitchen::ActionFailed
  >>>>>> Message: SSH exited (1) for command: [sh -c '
  sudo -E /opt/chef/bin/chef-client --local-mode --config /tmp/kitchen/client.rb --log_level auto --force-formatter --no-color --chef-zero-port 8889 --json-attributes /tmp/kitchen/dna.json
  ']
  >>>>>> ----------------------
```

Let's scroll up a bit until we find:

```bash
  After this operation, 5342 kB of additional disk space will be used.
  Err http://mirrors.digitalocean.com/ubuntu/ trusty-updates/main apache2-bin amd64 2.4.7-1ubuntu4.1
  404  Not Found [IP: 198.199.99.226 80]
  Err http://security.ubuntu.com/ubuntu/ trusty-security/main apache2-bin amd64 2.4.7-1ubuntu4.1
  404  Not Found [IP: 91.189.91.14 80]
  Err http://security.ubuntu.com/ubuntu/ trusty-security/main apache2-data all 2.4.7-1ubuntu4.1
  404  Not Found [IP: 91.189.91.14 80]
  Err http://security.ubuntu.com/ubuntu/ trusty-security/main apache2 amd64 2.4.7-1ubuntu4.1
  404  Not Found [IP: 91.189.91.14 80]
  STDERR: E: Failed to fetch http://security.ubuntu.com/ubuntu/pool/main/a/apache2/apache2-bin_2.4.7-1ubuntu4.1_amd64.deb  404  Not Found [IP: 91.189.91.14 80]

  E: Failed to fetch http://security.ubuntu.com/ubuntu/pool/main/a/apache2/apache2-data_2.4.7-1ubuntu4.1_all.deb  404  Not Found [IP: 91.189.91.14 80]

  E: Failed to fetch http://security.ubuntu.com/ubuntu/pool/main/a/apache2/apache2_2.4.7-1ubuntu4.1_amd64.deb  404  Not Found [IP: 91.189.91.14 80]

  E: Unable to fetch some archives, maybe run apt-get update or try with --fix-missing?
  ---- End output of apt-get -q -y install apache2=2.4.7-1ubuntu4.1 ----
  Ran apt-get -q -y install apache2=2.4.7-1ubuntu4.1 returned 100
```

```bash
  $ kitchen verify
```

We need to run apt-get update on our test instance before it can find and install the apache2 package.

Let's add that to our default Chef recipe.  Open up the recipe with:

```bash
  $ vim recipes/default.rb
```

And add this content:

```bash
  execute 'apt_update' do
    command "apt-get update"
    action :run
  end
```

Looks like we got a failure:

```bash
  1) my_web_server_cookbook::default Package "apache2" should be installed
    Failure/Error: it { should be_installed }
      expected Package "apache2" to be installed
      /bin/sh -c dpkg-query\ -f\ \'\$\{Status\}\'\ -W\ apache2\ \|\ grep\ -E\ \'\^\(install\|hold\)\ ok\ installed\$\'
      dpkg-query: no packages found matching apache2

    # /tmp/busser/suites/serverspec/default_spec.rb:9:in `block (3 levels) in <top (required)>'

  Finished in 0.13136 seconds (files took 0.43602 seconds to load)
  1 example, 1 failure
```

Excellent!  Our test looks for the apache2 package and, when it doesn't find it, fails.  Now let's make it pass.

Open up recipes/default.rb

```bash
  $ vim recipes/default.rb
```

And add this:

```bash
  package 'apache2' # Installs the apache2 package
```

Now, run:

```bash
  $ kitchen converge
```

To apply the Chef changes to the Test Kitchen instance, then run the test again with:

```bash
  $ kitchen verify
```

And you should see:

```bash
  my_web_server_cookbook::default
    Package "apache2"
      should be installed

  Finished in 0.12728 seconds (files took 0.40525 seconds to load)
  1 example, 0 failures

  Finished verifying <default-ubuntu-14-04-x64> (0m4.17s).
```

Huzzah! It passes!

Now we can be assured that our Chef recipe will install Apache2 if it's not already installed on any machine it runs on.

Now what if this recipe ran on a server that had Apache2 installed, but did not have the Apache2 service running?  Let's write a test to ensure that our recipe will start up the Apache2 service.

Open up your test file:
```bash
  $ vim test/integration/default/serverspec/default_spec.rb
```

And add this content:

```bash
  require 'spec_helper'

  describe 'my_web_server_cookbook::default' do

    # Serverspec examples can be found at
    # http://serverspec.org/resource_types.html

    describe package('apache2') do
      it { should be_installed }
    end

    describe service('apache2') do
      it { should be_running }
    end
  end
```

Now, run:

```bash
  $ kitchen converge
```

To apply the Chef changes to the Test Kitchen instance, then run the test again with:

```bash
  $ kitchen verify
```

And you should see this output:

```bash
  my_web_server_cookbook::default
    Package "apache2"
      should be installed
    Service "apache2"
      should be enabled

  Finished in 0.11753 seconds (files took 0.36669 seconds to load)
  2 examples, 0 failures
```

Whoa, looks like it passed the first time.  This is because when Ubuntu 14.04 installs apache2, it also starts the service.  How do we make it fail?

One of the nicest things about Test Kitchen is that you can ssh into a running Test Kitchen instance with this command:

```bash
  $ kitchen login
```

Go ahead and run this.  It will log you into the instance as root.  When you get into the instance, run this command:

```bash
  $ sudo service apache2 stop
```

Now exit out of the instance and re-run your tests with:

```bash
  $ kitchen verify
```

Now we get a failure:

Failures:

```bash
  1) my_web_server_cookbook::default Service "apache2" should be running
    Failure/Error: it { should be_running }
      expected Service "apache2" to be running
      /bin/sh -c service\ apache2\ status\ \&\&\ service\ apache2\ status\ \|\ grep\ \'running\'
      * apache2 is not running

    # /tmp/busser/suites/serverspec/default_spec.rb:13:in `block (3 levels) in <top (required)>'

  Finished in 0.15349 seconds (files took 0.42149 seconds to load)
  2 examples, 1 failure
```

Open up your default recipe:

```bash
  $ vim recipes/default.rb
```
And add this content:

```bash
  service 'apache2' do
    action [:start]
  end
```

[TO DO: Should there be a way to simulate the service not working with test kitchen?]

Now re-run the tests with:

```bash
  $ kitchen converge
```

Then:

```bash
  $ kitchen verify
```

Now our test passes!

Let's add another test for another expectation of our Chef recipe.  Anytime Chef runs on our machine, we want to make sure that apache2 is setup to start anytime the machine boots.

Open up your test file:

```bash
  $ vim test/integration/default/serverspec/default_spec.rb
```

And add this content:

```bash
  require 'spec_helper'

  describe 'my_web_server_cookbook::default' do

    # Serverspec examples can be found at
    # http://serverspec.org/resource_types.html

    describe package('apache2') do
      it { should be_installed }
    end

    describe service('apache2') do
      it { should be_running }

      it { should be_enabled }
    end
  end
```

Now run the specs with "kitchen verify"

```bash
  $ kitchen verify
```

And we get a pass.  We can't write code in our recipe until that test fails.  Login to your kitchen instance with:

```bash
  $ kitchen login
```

Then remove apache2 from the boot start up list by running this command:

```bash
  $ sudo update-rc.d -f apache2 disable
```

Exit out of your test kitchen instance.

Back in your development environment, run your specs again:

```bash
  $ kitchen verify
```

And this time our test fails as expected.

```bash
  Failures:

  1) my_web_server_cookbook::default Service "apache2" should be enabled
    Failure/Error: it { should be_enabled }
      expected Service "apache2" to be enabled
      /bin/sh -c ls\ /etc/rc3.d/\ \|\ grep\ --\ \'\^S..apache2\'\ \|\|\ grep\ \'start\ on\'\ /etc/init/apache2.conf
      grep: /etc/init/apache2.conf: No such file or directory

    # /tmp/busser/suites/serverspec/default_spec.rb:15:in `block (3 levels) in <top (required)>'

  Finished in 0.13878 seconds (files took 0.40043 seconds to load)
  3 examples, 1 failure
```

Now let's make it pass.  Open up you default recipe:

```bash
  $ vim recipes/default.rb
```

And add in this content:

```bash
  service 'apache2' do
    action [:start, :enable]
  end
```

Then apply the Chef recipe to your instance with:

```bash
  $ kitchen converge
```

And run the tests.

```bash
  $ kitchen verify
```

And now it passes!

Finally, let's add in a custom home page.  First, a test.  Open up your test file:

```bash
  $ vim test/integration/default/serverspec/default_spec.rb
```

And add this content:

```bash
  require 'spec_helper'

  describe 'my_web_server_cookbook::default' do

    # Serverspec examples can be found at
    # http://serverspec.org/resource_types.html

    describe package('apache2') do
      it { should be_installed }
    end

    describe service('apache2') do
      it { should be_running }

      it { should be_enabled }
    end

    describe file('/var/www/html/index.html') do
      its(:content) { should match /<h1>I AM A CUSTOM PAGE<\/h1>/ }
    end
end
```

Now run the test:

```bash
  $ kitchen verify
```

The output is very verbose for this failure, the sum of it is it hasn't found the content it expected to find.

To place this content in that file with Chef, we need to add a template.  Chef offers a convenient generator method for creating a template.

Make sure you're back in the root directory for you Chef repo:

```bash
  $ cd ~/my_web_server_chef_repo
```

Then run:

```bash
  $ chef generate template cookbooks/my_web_server_cookbook index.html
```

Then change directories back into your my_web_server_cookbook cookbook

```bash
  $ cd cookbooks/my_web_server_cookbook
```

When you ran that generate command above, it placed a file in the templates directory of your cookbook.  Take a look at the templates directory:

```bash
  $ ls templates/default
```

You should see a file called "index.html.erb"  This is the template for your custom home page.  Go ahead and open it up:

```bash
  $ vim templates/default/index.html.erb
```

And add this content:

```bash
  <h1>I AM A CUSTOM PAGE</h1>
```

Then save and close the file.

Now let's reference this template in our default recipe.  Open it with:

```bash
  $ vim recipes/default.rb
```

And add this content:

```bash
  template '/var/www/html/index.html' do
    source 'index.html.erb'
  end
```

Then save and close the file.

Now converge:

```bash
  $ kitchen converge
```

The run your tests with:

```bash
  $ kitchen verify
```

And our test passes!

Let's do one final run - destroying this instance, creating a new instance, converging Chef, and running the tests.  Test Kitchen has a one stop command for all of these things.  Run:

```bash
  $ kitchen test
```

It'll take a bit to run, but by the end you should see all specs passing.

Now we have a test driven Chef recipe to install Apache!
