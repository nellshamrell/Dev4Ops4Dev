# Installing Ruby

Now let's create a recipe which will install Ruby and all its associated dependencies.

Let's generate a new recipe like so:

```bash
  $ chef generate recipe ruby
```

## Installing a base Ruby

We need to install a base version of Ruby for our system to use (though we will later be managing Ruby versions through RVM).  First, let's write a test:

Open up your test file:

```bash
  $ vim test/integration/ruby/serverspec/ruby_spec.rb
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
```

Next you'll need to create a new test instance for the new suite:

```bash
  $ kitchen create ruby-ubuntu-14-04-x64
```

And then set it up with Chef:

```bash
  $ kitchen setup ruby-ubuntu-14-04-x64
```

Now, run the tests:

```bash
  $ kitchen verify ruby-ubuntu-14-04-x64
```
```

And you should see a failure.  Now open your recipe file:

```bash
  $ vim recipes/ruby.rb
```
 And add in this content:

```bash
  $ package ruby
```

Now apply the Chef changes to your kitchen instance:

```bash
  $ kitchen converge ruby-ubuntu-14-04-x64
```

And run your test again:

```bash
  $ kitchen verify ruby-ubuntu-14-04-x64
```

And it should pass!

## Installing Ruby Dependencies

Ruby depends on several packages already being installed:

```bash
git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties
```

Now let's create a test for each of these packages.  Open up the test file:

```bash
  $ vim test/integration/ruby/serverspec/ruby_spec.rb
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
  $ kitchen verify
```

You'll see several failures.

Now let's add in the code to make these tests pass.

Open up your recipe file:

```bash
  $ vim recipes/ruby.rb
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
  $ kitchen converge
```

And run your tests:

```bash
  $ kitchen verify
```

And now they should all pass!

## Installing RVM and Ruby

[TO DO: Explain more about RVM]

Installing RVM with Chef is can be complicated.  Fortunately, someone has already done much of the work for us.  Rather than creating your own, it is sometimes much easier to use a community cookbook.

The community cookbook we're using is the [rvm cookbook](https://supermarket.chef.io/cookbooks/rvm), available on the Chef Supermarket community cookbook site.

## Chef Supermarket

We can pull the cookbook down from the Supermarket using Knife, a tool included with ChefDK.

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

Then create and open a file within that directory:

```bash
  $ vim ~/.chef/knife.rb
```

And add this content.  This ensures that knife will always looks for cookbooks within the working directory we are working in.

```bash
  current_chef_dir = File.dirname(__FILE__)
  working_dir = Dir.pwd

  cookbook_paths = []
  # some common paths created by `berks install` with `--path` option
  cookbook_paths << File.join(working_dir, "cookbooks")
  cookbook_paths << File.join(working_dir, "vendor", "cookbooks")
  # traditional chef-repo cookbook path
  cookbook_paths << File.join(current_chef_dir, "..", "cookbooks")
```

Now try it again:

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

```bash
  $ vim metadata.rb
```

And add this line to the file

```bash
  depends 'rvm'
```

Save and close the file.

Now let's add a test to ensure that Ruby 2.1.3 is installed through rvm.

[TO DO: Explain why we need to use 'bash -l -c' with Test Kitchen and ServerSpec]

```bash
  require 'spec_helper'

  describe 'my_web_server_cookbook::ruby' do
    describe command('bash -l -c "rvm list"') do
      its(:stdout) { should match /ruby-2.1.3/ }
    end
  end
```

First, let's run those tests and watch them fail:

```bash
  $ kitchen verify
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
  $ kitchen converge
```

And run the tests again:

```bash
  $ kitchen verify
```

Ruby and RVM are working!
