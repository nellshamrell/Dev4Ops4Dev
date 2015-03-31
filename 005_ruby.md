# Installing Ruby

Now let's create a recipe which will install Ruby and all its associated dependencies.

Let's generate a new recipe like so:

```bash
 vagrant@workshop $ chef generate recipe ruby
```

Now we need to create the directory where our server specs will live:

```bash
 vagrant@workshop $ mkdir -p test/integration/ruby/serverspec
```

And create the test file

```bash
 vagrant@workshop $ touch test/integration/ruby/serverspec/ruby_spec.rb
```

And we need to be able to access a spec_helper similar to the one living in test/integration/default/serverspec.  In this case, let's copy that one into our new integration test directory.

```bash
 vagrant@workshop $ cp test/integration/default/serverspec/spec_helper.rb test/integration/ruby/serverspec
```

## Installing a base Ruby

We need to install a base version of Ruby for our system to use (though we will later be managing Ruby versions through RVM).  First, let's write a test:

Open up your test file:

```bash
 vagrant@workshop $ vim test/integration/ruby/serverspec/ruby_spec.rb
```

 And add in this content:

```bash
  require 'spec_helper'
   describe 'my_web_server_cookbook::ruby' do
     describe package('ruby') do
       it { should be_installed }
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
```

Next you'll need to create a new test instance for the new suite:

```bash
 vagrant@workshop $ kitchen create ruby-ubuntu-14-04-x64
```

And then converge on it.

```bash
 vagrant@workshop $ kitchen converge ruby-ubuntu-14-04-x64
```

Now, run the tests:

```bash
 vagrant@workshop $ kitchen verify ruby-ubuntu-14-04-x64
```

And you should see a failure.

Let's commit this to git:

```bash
 vagrant@workshop $ git add recipes/ruby.rb test/integration/ruby/serverspec/ruby.rb .kitchen.yml
```

```bash
  vagrant@workshop $ git commit -m 'failing ruby package test'
```

Now open your recipe file:

```bash
 vagrant@workshop $ vim recipes/ruby.rb
```
 And add in this content:

```bash
  package 'ruby'
```

Now apply the Chef changes to your kitchen instance:

```bash
 vagrant@workshop $ kitchen converge ruby-ubuntu-14-04-x64
```

And run your test again:

```bash
 vagrant@workshop $ kitchen verify ruby-ubuntu-14-04-x64
```

And it should pass!

Let's commit this to git:

```bash
 vagrant@workshop $ git add recipes/ruby.rb
```

```bash
  vagrant@workshop $ git commit -m 'passing ruby package test'
```

## Installing Ruby Dependencies

Ruby depends on several packages already being installed:

```bash
git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties
```

Now let's create a test for each of these packages.  Open up the test file:

```bash
 vagrant@workshop $ vim test/integration/ruby/serverspec/ruby_spec.rb
```
 And add in this content:

```bash
  describe package('git-core') do
    it { should be_installed }
  end

  describe package('curl') do
    it { should be_installed }
  end

  describe package('zlib1g-dev') do
    it { should be_installed }
  end

  describe package('build-essential') do
    it { should be_installed }
  end

  describe package('libssl-dev') do
    it { should be_installed }
  end

  describe package('libreadline-dev') do
    it { should be_installed }
  end

  describe package('libyaml-dev') do
    it { should be_installed }
  end

  describe package('libsqlite3-dev') do
    it { should be_installed }
  end

  describe package('libxml2-dev') do
    it { should be_installed }
  end

  describe package('libxslt1-dev') do
    it { should be_installed }
  end

  describe package('libcurl4-openssl-dev') do
    it { should be_installed }
  end

  describe package('python-software-properties') do
    it { should be_installed }
  end
```

Then run these tests on your instance:

```bash
 vagrant@workshop $ kitchen verify ruby-ubuntu-14-04-x64
```

You'll see several failures.

Commit this:

```bash
 vagrant@workshop $ git add test/integration/ruby/serverspec/ruby.rb
```

```bash
  vagrant@workshop $ git commit -m 'failing ruby dependencies tests'
```

Now let's add in the code to make these tests pass.

Open up your recipe file:

```bash
 vagrant@workshop $ vim recipes/ruby.rb
```

And add in this content:

```bash
  package 'git-core'

  package 'curl'

  package 'zlib1g-dev'

  package 'build-essential'

  package 'libssl-dev'

  package 'libreadline-dev'

  package 'libyaml-dev'

  package 'libsqlite3-dev'

  package 'sqlite3'

  package 'libxml2-dev'

  package 'libxslt1-dev'

  package 'libcurl4-openssl-dev'

  package 'python-software-properties'
```

Now apply these changes to your test instance with:

```bash
 vagrant@workshop $ kitchen converge ruby-ubuntu-14-04-x64
```

Whoops, looks like we need to run apt-get update here as well.  Fortunately, we can include the default recipe with this one, which will ensure that apt-get update runs.  Add this content to the top of your recipes/ruby.rb file.

```bash
  include_recipe 'my_web_server_cookbook::default'
```

Apply these changes:

```bash
 vagrant@workshop $ kitchen converge ruby-ubuntu-14-04-x64
```

And run your tests:

```bash
 vagrant@workshop $ kitchen verify ruby-ubuntu-14-04-x64
```

And now they should all pass!

Let's commit this to git:

```bash
 vagrant@workshop $ git add recipes/ruby.rb
```

```bash
  vagrant@workshop $ git commit -m 'passing ruby dependencies tests'
```

## Installing RVM and Ruby

Ruby has several different versions, the most recent of which is Ruby 2.1. It helps immensely to have a Ruby Version Manager to deal with compiling and managing Ruby versions.  For this workshop, we're going to use [RVM](https://rvm.io/), but there are also alternatives including [rbenv](https://github.com/sstephenson/rbenv) and [chruby](https://github.com/postmodern/chruby)

Installing RVM with Chef can be frustratingly complicated.  Fortunately, someone has already done much of the work for us.  Rather than creating your own, it is sometimes much easier to use a community cookbook.

The community cookbook we're using is the [rvm cookbook](https://supermarket.chef.io/cookbooks/rvm), available on the Chef Supermarket community cookbook site.

## Chef Supermarket

We can pull the cookbook down from the [Supermarket](https://supermarket.chef.io/) (Chef's Community Cookbook Site) using Knife, a tool included with ChefDK.

```bash
  $ knife cookbook site install rvm
```
Whoops!  Looks like we got an error:

```bash
  WARNING: No knife configuration file found
  Installing rvm to /home/vagrant/.chef/cookbooks
  ERROR: The cookbook repo path /home/vagrant/.chef/cookbooks does not exist or is not a directory
```

## Configuring Knife

We need to add a config file for Knife.  I like to keep mine in a .chef directory.

First, let's make that directory:

```bash
  $ mkdir ~/.chef
```

Then create and open a file within that directory with your editor of choice:

```bash
  $ sudo vim ~/.chef/knife.rb
```

And add this content.  This ensures that knife will always looks for cookbooks within the working directory we are working in.

```bash
  cookbook_path ['~/my_web_server_chef_repo/cookbooks/']
```

Now try it again:

```bash
  $ knife cookbook site install rvm
```

Whoops, there's another error:

```bash
  ERROR: The cookbook repo /home/vagrant/my_web_server_chef_repo/cookbooks is not a git repository.
  Use `git init` to initialize a git repo
```

The my_web_server_chef_repo/cookbooks directory needs to be a git repository.  Change to that directory:

```bash
  $ cd ~/my_web_server_chef_repo/cookbooks
```

And run this command:

```bash
  $ git init
```

Now we need to have at least one commit.  Add in the README.md

```bash
  $ git add README.md
```

Then commit the file

```bash
  $ git commit -m 'Initial Commit'
```

Now run the install command one more time:

```bash
  $ knife cookbook site install rvm
```

There will be lots of output, but at the end you'll see:

```bash
  Cookbook chef_gem version 0.1.0 successfully installed
```

## Using this cookbook

The [rvm cookbook GitHub Page](https://github.com/martinisoft/chef-rvm) has good instructions on how to use the community cookbook to install RVM and Ruby.

Next, you need to add the dependency on the rvm cookbook to your metadata file in your cookbook.

Change back to the my_web_server_cookbook directory:

```bash
 vagrant@workshop $ cd my_web_server_cookbook
```

And open up the metadata file.

```bash
 vagrant@workshop $ vim metadata.rb
```

And add this line to the file

```bash
  depends 'rvm'
```

Save and close the file.

Now let's add a test to ensure that Ruby 2.1.3 is installed through rvm.

test/integration/ruby/serverspec/ruby_spec.rb
```bash
  describe command('bash -l -c "rvm list"') do
    its(:stdout) { should match /ruby-2.1.3/ }
  end
```

First, let's run those tests and watch them fail:

Then commit:

```bash
 vagrant@workshop $ git add test/integration/ruby/serverspec/ruby.rb
```

```bash
  vagrant@workshop $ git commit -m 'failing rvm test'
```

```bash
 vagrant@workshop $ kitchen verify ruby-ubuntu-14-04-x64
```

Now open up your recipe file and add in this content to make the tests pass.  Note that we need to include the default recipe from the rvm cookbook we just downloading from Supermarket.

```bash
  include_recipe 'rvm::system_install'

  rvm_ruby "ruby-2.1.3" do
    action :install
  end
```

Now apply the Chef changes:

```bash
 vagrant@workshop $ kitchen converge ruby-ubuntu-14-04-x64
```

And run the tests again:

```bash
 vagrant@workshop $ kitchen verify ruby-ubuntu-14-04-x64
```

Ruby and RVM are working!

Let's commit this!

```bash
 vagrant@workshop $ git add recipes/ruby.rb
```

```bash
  vagrant@workshop $ git commit -m 'passing rvm test'
```
