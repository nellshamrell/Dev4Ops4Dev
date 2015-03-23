# Deploying Code and Services to Nodes

## Problem

So, we have the code, in widgetworld/ .  And we know what services / platform components we need:

 * Apache
 * Ruby
 * Something to let Ruby run under Apache, like Passenger
 * PostgreSQL

We'd like to get all those parts onto our target nodes in a repeatable, verifiable way.  This is where Configuration Management tools like Chef come into play.  While there are several alternatives, at this workshop we'll focus on using Chef.

## Exercise

### Configuring Apache by Hand

[TODO - Nell has excellent content on this ]

### Creating a Chef Repo

First, we need to create a Chef repo of our own.  This will contain all our cookbooks, templates, etc. for our web server.

#### Placing the code in git

Since this is source code, we should be careful to keep it under version control.  That way we can iterate on it over time, identify versions, and work on separate lines of development.

Visit your GIthub page, and click the '+' next to your name in the upper right.  Choose create repository.

Create a repo name 'widget-chef', and check "Create a README".

Copy the SSH git repo URL.

In your development machine, run 

```bash
  vagrant@workshop $ git clone git@github.com:YOUR_GITHUB_NAME/widget-chef.git
```

#### Generating a template

Make sure you're on your DEVELOPMENT VM and run


```bash
  vagrant@workshop $ chef generate repo widget-chef
```

Then CD into that directory:

```bash
  vagrant@workshop $ cd widget-chef
  vagrant@workshop widget-chef $ tree
```

The command generated a set of files that you can use as a starting point for a Chef setup.

#### Commit the generated files.

```bash
  vagrant@workshop widget-chef $ git add .
  vagrant@workshop widget-chef $ git commit -m "Boilerplate files from chef generate repo"
```

### Adding an Apache cookbook to your repo

So, we know we need to support several services.  Let's start with apache, as it's fairly straightforward.

#### Generating the cookbook

```bash
  vagrant@workshop widget-chef $ chef generate cookbook cookbooks/my-apache
  vagrant@workshop widget-chef $ git add cookbooks/my-apache/
  vagrant@workshop widget-chef $ git commit -m "Initial generation of my-apache cookbook"
```

Open up that metadata.rb file in your my_web_server_cookbook directory.  Use your preferred text editor (here I use vim).

```bash
  vagrant@workshop widget-chef $ vim cookbooks/my-apache/metadata.rb
```

You should see content similar to this:

```bash
  name             'my-apache'
  maintainer       'The Authors'
  maintainer_email 'you@example.com'
  license          'all_rights'
  description      'Installs/Configures apache'
  long_description 'Installs/Configures apache'
  version          '0.1.0'
```

Change the maintainer and maintainer values to your name and your email respectively.  Leave the other values as they are for now.

Commit your changes:

```bash
  vagrant@workshop widget-chef $ git commit -m "Update README with my name" cookbooks/my-apache/metadata.rb
```

#### Why not use the community cookbook?

Firstly, we want to teach you :)  Secondly, in this particular case, the apache2 community cookbook is fairly complex, and strives to be very flexible.  In this case, our needs are simple.

#### Why not just dive in?

We think it is important to state your expectations before your run code.  How else would you know if it worked?  Based on that idea, we're going to make a quick side-journey to setup a test harness.

#### How we test: TestKitchen + DigitalOcean

To Test Drive creating our Apache Chef cookbook, we're going to use a test framework called [Test Kitchen](https://github.com/test-kitchen/test-kitchen).

Test Kitchen is included in the ChefDK you downloaded earlier.  Verify that it is on your system by running:

```bash
  vagrant@workshop widget-chef $ kitchen version
```

You should see output similar to:

```bash
  Test Kitchen version 1.3.1
```

ChefDK will include all the Test Kitchen templates that we need.

##### Setting up Test Kitchen within your cookbook

Change directories to your my-apache cookbook

```bash
  vagrant@workshop widget-chef $ cd cookbooks/my-apache
```

List all files and directories, including hidden files

[TO DO: Explain -a flag more?)

```bash
  vagrant@workshop my-apache $ ls -la
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
  vagrant@workshop my-apache $ vim .kitchen.yml
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
      - recipe[my-apache::default]
    attributes:
```

See those first two lines where we define what driver we want test kitchen to use?  That defines what platform we want the VM test kitchen will spin up to run on.  By default, Test Kitchen will spin up a Vagrant VM and normally this is how I run Test Kitchen.


However, all of us in this workshop are already developing on Vagrant VMs.  Spinning up a VM within a VM is messy at best, fortunately there are other platforms Test Kitchen can use to spin up a VM.  We're going to use Digital Ocean.

##### DigitalOcean Setup

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
      - recipe[my-apache::default]
    attributes:
```

Save and close the file.

Commit your changes:

```bash
  vagrant@workshop my-apache $ git commit -m "Switch Test Kitchen to use Digital Ocean" .kitchen.yml
```


Now run the command:

```bash
  vagrant@workshop my-apache $ kitchen list
```

You should receive output similar to this:

```bash
  Instance             Driver        Provisioner  Last Action
  default-ubuntu-1404  Digitalocean  ChefZero     <Not Created>
```

This means Test Kitchen is now aware there is an environment it needs to run tests against our cookbook in, but it has not yet been created.

##### Creating the Test Instance

Let's go ahead and create this instance for Test Kitchen on Digital Ocean:

```bash
  vagrant@workshop my-apache $ kitchen create default-ubuntu-1404
```

This will take a little bit while Digital Ocean spins up the instance and gets it ssh ready.  you should receive this confirmation message within 6-7 minutes:


```bash
  Finished creating <default-ubuntu-1404> (5m15.98s).
  -----> Kitchen is finished. (5m16.34s)
```

Alright, let's run kitchen list again:

```bash
  vagrant@workshop my-apache $ kitchen list
```

You should see output similar to this:

```bash
  Instance             Driver        Provisioner  Last Action
  default-ubuntu-1404  Digitalocean  ChefZero     Created
```

The final thing we need to do is install Chef Client on this instance in order to run our tests.  To do that, run:

```bash
  vagrant@workshop my-apache $ kitchen setup
```

You'll see lots of output.  When it completes, run kitchen list one last time:
```bash
  vagrant@workshop my-apache $ kitchen list
```

Now you'll see this output:
```bash
  Instance             Driver        Provisioner  Last Action
  default-ubuntu-1404  Digitalocean  ChefZero     Set Up
```

##### Verifying Recipe Execution


First, let's make sure that Test Kitchen can run our code.

Open up recipes/default.rb

```bash
  vagrant@workshop my-apache $ vim recipes/default.rb
```

And add this content.

```bash
  log "TEST KITCHEN IS RUNNING MY CODE!!!"
```

Save and close the file.

Now we'll use Test Kitchen to run this code.  To do this, we use the "kitchen converge" command:

```bash
  vagrant@workshop my-apache $ kitchen converge
```

At some point in the output, you should see this:

```bash
  Recipe: my_web_server_cookbook::default
    * log[TEST KITCHEN IS RUNNING MY CODE!!!] action write
```

Huzzah!  This means Test Kitchen can run our cookbook!

Commit your work:

```bash
  vagrant@workshop my-apache $ vagrant@workshop my-apache $ git commit -m "Log message to veify test kitchen execution" recipes/default.rb
```

And now we're ready to write and run some tests!













#### TDD Red: Creating a Failing Test

One of the benefits of Test Driven Development is that it forces you to clarify exactly what you want your code to do before you run it.  Let's clarify that we want our cookbook to install apache2 with a test.

To do this, we will use something called [ServerSpec].  ServerSpec allows us to write [RSpec](http://rspec.info/) tests (RSpec is a domain specific language used for testing Ruby code).  ServerSpec is automatically included with ChefDK.

Our tests will live in the /test/integration directory of our cookbook.  Go ahead and take a look at the contents of that directory with:

```bash
  vagrant@workshop my-apache $ ls test/integration
```

You'll see a directory called "default."  This is where the specs for our default recipe will live.  Go ahead and take a look inside that directory.

```bash
  vagrant@workshop my-apache $ ls test/integration/default
```

You'll now see a directory called "serverspec."  There are multiple testing languages that can be used with test kitchen and here is where you would provide directories for each language.  We're using serverspec and the serverspec directory is already there, so we're good to go.

Take a look in the serverspec directory:

```bash
  vagrant@workshop widget-chef my-apache$ ls test/integration/default/serverspec
```

You'll see two files: default_spec.rb and spec_helper.rb.  Open up default_spec.rb:

```bash
  vagrant@workshop widget-chef my-apache$ vim test/integration/default/serverspec/default_spec.rb
```

And you'll see a placeholder spec that looks like this:

```bash
require 'spec_helper'

describe 'my-apache::default' do

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

describe 'my-apache::default' do

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
  vagrant@workshop widget-chef my-apache$ kitchen list
```

You should see:

```bash
  Instance                  Driver        Provisioner  Last Action
  default-ubuntu-14-04-x64  Digitalocean  ChefZero     Converged
```

Now let's run our test.

```bash
  vagrant@workshop my-apache$ kitchen verify
```

As expected, this fails:

```bash
       my-apache::default
         Package "apache2"
           should be installed (FAILED - 1)

       Failures:

         1) my-apache::default Package "apache2" should be installed
            Failure/Error: it { should be_installed }
              expected Package "apache2" to be installed
              /bin/sh -c dpkg-query\ -f\ \'\$\{Status\}\'\ -W\ apache2\ \|\ grep\ -E\ \'\^\(install\|hold\)\ ok\ installed\$\'
              dpkg-query: no packages found matching apache2

            # /tmp/busser/suites/serverspec/default_spec.rb:9:in `block (3 levels) in <top (required)>'

       Finished in 0.13224 seconds (files took 0.42583 seconds to load)
       1 example, 1 failure
```

Commit your work - having a RED test is a good thing, at this point.

```bash
  vagrant@workshop my-apache $ git commit -m "TDD RED for apache2 package installation" test/integration/default/serverspec/default_spec.rb
```


#### TDD Green: Making it Work

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

Then add the important part:

```bash
  package 'apache2'
```

After every Chef change, you'll need to run kitchen converge to run Chef:

```bash
  vagrant@workshop my-apache$ kitchen converge
```

Then run the tests!  They should pass.

```bash
  vagrant@workshop my-apache$ kitchen verify
```

Commit your work, this is a key checkpoint:

```bash
  vagrant@workshop my-apache $ git commit -m "TDD GREEN for apache2 package installation" recipes/default.rb
```

[ TODO - add section on ensuring service start ] 


### Pulling in cookbooks we provide for Passenger, Postgres, and Ruby

### A cookbook to deploy the widgetworld app

Now let's make a cookbook that will deploy the widgetworld app, relying on the other cookbooks.

```bash
  vagrant@workshop widget-chef $ chef generate cookbook cookbooks/widgetworld-app
  vagrant@workshop widget-chef $ git add cookbooks/widgetworld-app/
  vagrant@workshop widget-chef $ git commit -m "Initial generation of widgetworld-app cookbook"
  vagrant@workshop widget-chef $ cd cookbooks/widgetworld-app/
```

Now, open up your .kitchen.yml file and modify it so it looks like this:

```bash
  vagrant@workshop widgetworld-app $ vim .kitchen.yml
```


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
      - recipe[widgetworld-app::default]
    attributes:
```

Save and close the file.


Ask kitchen to prep the instance:

```bash
  vagrant@workshop widgetworld-app $ kitchen setup
```

Commit your changes:

```bash
  vagrant@workshop widgetworld-app $ git commit -m "Switch Test Kitchen to use Digital Ocean" .kitchen.yml
```

#### TDD Red: What does widgetworld look like?

Well, it's a rails app.  The code should be deployed on the filesystem, and it should respond on port 80, with something that is not the Apache homepage. [ TODO - need an app-specific real response ]

Let's express that in serverspec.

```bash
  vagrant@workshop widgetworld-app$ vim test/integration/default/serverspec/default_spec.rb
```

First let's add the code deployment.

```bash
  describe file('/opt/widgetworld') do
    it { should be_directory }
  end
```

Next, let's add the port 80 requirement.

```bash
  describe port(80) do
    it { should be_listening }
  end 
```

Finally, try HTTP, and see what we got back.

```bash
  describe command('curl http://127.0.0.1') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should_not match(/Apache/) }
  end
```

All of that should fail.

Commit your changes:

```bash
  vagrant@workshop widgetworld-app $ git commit -m "TDD RED - Web app deployment checks" test/integration/default/serverspec/default_spec.rb
```

#### TDD Green: Making it run

##### Deploying the Code

There are a lot of ways to deploy code using Chef.  

[ TODO - Code deploy using terrible ideas ]

##### Running Apache

Obviously, we just developed an my-apache cookbook!  We should somehow refer to it, and use it.

Calling one cookbook's recipes from another is called a cookbook dependency.  We add one by doing three things.  First, we declare that we are going to rely on the my-apache cookbook by adding a 'depends' statement to the metadata file:

```bash
  vagrant@workshop widgetworld-app $ vim metadata.rb
```

Add:

```bash
   depends 'my-apache'
```

Also modify the Author, if you haven't already.

Next, we need to tell Chef to execute the my-apache cookbook's default recipe at some point.  There are several ways to do this, but this is one of the simplest:

```bash
  vagrant@workshop widgetworld-app $ vim recipes/default.rb
```

Add:

```bash
   include_recipe 'my-apache::default'
```

Finally, we need to tell the dependency resolver, known as Berkshelf,  how to find the my-apache cookbook.  

```bash
  vagrant@workshop widgetworld-app $ vim Berksfile
```

Add: 

```bash
   cookbook 'my-apache', path: '../my-apache'
```



## Enrichment

### A custom postgres cookbook

[TODO - Nell has started on this ]

#### Why not use the community cookbook?

### A custom passenger cookbook

[TODO - Nell has started on this ]

### A custom ruby cookbook

[TODO - Nell has started on this ]
