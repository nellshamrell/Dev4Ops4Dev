Apache is the main piece of our web server, in fact it's called a "Web Server."  It's what enables communication over networks, which allows our server to connect and be connected to the outside world.

# Install Apache by hand

## Setting up a clean Ubuntu Server

Let's spin up a clean copy of a server running Ubuntu to practice installing Apache. (This is a separate Vagrant box from the development environment)

Create a new directory in your workshop directory, maybe call it "hand_crafted_apache" or something to that effect.

Initiate a Vagrant file with:

```bash
  vagrant init ubuntu/trusty64
```

[TO DO: Explore if there is a way to do this locally)

Then spin up the Vagrant VM.

```bash
  vagrant up
```

Then SSH into the VM

[TO DO: Add any special instructions for Windows]

```bash
  vagrant ssh
```

## Installing the Apache package

Run:

```bash
(VM) $ sudo apt-get install apache2
```

Once this is complete, let's verify that Apache is working on this VM.  Run this command:

```bash
(VM) $ wget -qO- 127.0.0.1
```
If Apache is installed correctly, the command line will output an html document which includes the words "It works!"

Now we are done with this VM.  Go ahead and exit out of it, then run "vagrant destroy", and navigate back to your development VM.

# Install Apache with Chef

Installing Apache by hand may work well on one or two servers - but imagine a fleet of hundreds or thousands of servers.  Installing Apache on all of them by hand, then keeping them updated and synced by hand, would be unmanageable.  Fortunately, as we are a ChefConf, we can use Chef to capture this installation of Apache in a cookbook and enable us to automate it across rows and rows of servers.

## Creating a Chef Repo for our cookbooks, etc.

First, we need to create a Chef repo of our own.  This will contain all our cookbooks, templates, etc. for our web server.

Make sure you're on your DEVELOPMENT VM and run

```bash
  $ chef generate repo my_web_server_chef_repo
```

Then CD into that directory:

```bash
  $ cd my_web_server_chef_repo
```

## Creating a Cookbook

Now, let's create an actual cookbook to manage our Apache installs.

```bash
  $ chef generate cookbook cookbooks/apache2_cookbook
```

Chef automatically generates several files and directories within cookbooks/apache2_cookbook.  Let's take a quick look:


```bash
  $ ls cookbooks/apache2_cookbook/
  Berksfile  chefignore  metadata.rb  README.md  recipes  spec  test
```

Let's open up that metadata.rb file.  Use your preferred text editor (here I use vim).

```bash
  $ vim cookbooks/apache2_cookbook/metadata.rb
```

You should see content similar to this:

```bash
  name             'apache2_cookbook'
  maintainer       'The Authors'
  maintainer_email 'you@example.com'
  license          'all_rights'
  description      'Installs/Configures apache2_cookbook'
  long_description 'Installs/Configures apache2_cookbook'
  version          '0.1.0'
```

Change the maintainer and maintainer values to your name and your email respectively.  Leave the other values as they are for now.

### Creating a recipe to install Apache

Cookbooks always contain recipes and our's is no different.  When we create a cookbook with the chef generate cookbook command, it auomatically creates a recipes directory.  Even better, there's already a recipe included called "default.rb".  Open up the default.rb recipe with your favorite text editor (here I use Vim).

```bash
  $ vim cookbooks/apache2_cookbook/recipes/default.rb
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
  $ sudo chef-client --local-mode --runlist 'recipe[apache2_cookbook]'
```

Take a look at the output, you should see these lines toward the end:

```bash
  Recipe: apache2_cookbook::default
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
  $ vim cookbooks/apache2_cookbook/recipes/default.rb
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
  $ sudo chef-client --local-mode --runlist 'recipe[apache2_cookbook]'
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
  $ rm -rf cookbooks/apache2_cookbook
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
  $ chef generate cookbook cookbooks/apache2_cookbook
```

Open up that metadata.rb file in your apache2_cookbook directory.  Use your preferred text editor (here I use vim).

```bash
  $ vim cookbooks/apache2_cookbook/metadata.rb
```

You should see content similar to this:

```bash
  name             'apache2_cookbook'
  maintainer       'The Authors'
  maintainer_email 'you@example.com'
  license          'all_rights'
  description      'Installs/Configures apache2_cookbook'
  long_description 'Installs/Configures apache2_cookbook'
  version          '0.1.0'
```

Change the maintainer and maintainer values to your name and your email respectively.  Leave the other values as they are for now.

Test Kitchen specifically uses the name and version attributes.

### Setting up Tesk Kitchen within your cookbook

Change directories to your apache2 cookbook

```bash
  $ cd cookbooks/apache2_cookbook
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
      - recipe[apache2_cookbook::default]
    attributes:
```

See those first two lines where we define what driver we want test kitchen to use?  That defines what platform we want the VM test kitchen will spin up to run on.  By default, Test Kitchen will spin up a Vagrant VM and normally this is how I run Test Kitchen.

However, all of us in this workshop are already developing on Vagrant VMs.  Spinning up a VM within a VM is messy at best, fortunately there are other platforms Test Kitchen can use to spin up a VM.  We're going to use AWS.

For Test Kitchen to use AWS, we need to install an additional gem on in our Development Environment - kitchen-ec2

[TO DO: Go over what ec2 means?  Do this earlier in the workshop?]
[TO DO: Should we include this gem as part of a workstation setup Chef recipe?]

To install kitchen-ec2, run this command:

```bash
  $ sudo chef gem install kitchen-ec2
```

Putting "chef" before "gem install" ensures that we will use the ChefDK version of Ruby.

This will take a little bit.

Next, we need to add a key to our ~/.aws directory to authorize Test Kitchen to spin up a VM.

[TO DO: How will they get this key?]

Create the key file with this command:

```bash
  $ touch ~/.aws/key.pem
```

Then open that file.  Copy and paste your key into there, then save and close the file.

[TO DO: How will they get the key to copy and paste?]


