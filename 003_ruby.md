# Installing Ruby

Now let's create a recipe which will install Ruby and all its associated dependencies.

Let's generate a new recipe like so:

```bash
  $ chef generate recipe ruby
```

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
  require 'spec_helper'
   describe 'my_web_server_cookbook::ruby' do
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

[==========broken===========]
```bash
  require 'spec_helper'

  describe 'my_web_server_cookbook::ruby' do
    describe command('rvm -v') do
      its(:stdout) { should match /rvm 1.26.10 \(latest\) by Wayne E. Seguin <wayneeseguin@gmail.com>, Michal Papis <mpapis@gmail.com> \[https:\/\/rvm.io\/\]/ }
    end
  end
```
[==========/broken===========]

Open up your recipe file and add in this content:

```bash
  rvm_ruby "ruby-2.1.3" do
    action :install
  end
```

Now apply the Chef changes:

```bash
  $ kitchen converge
```

Now ssh into your kitchen instance

```bash
  $ kitchen login
```

And run this command:

```bash
  $ rvm list
```

You should see output similar to this:

```bash
  rvm rubies

   * ruby-2.1.3 [ x86_64 ]
```

Ruby and RVM are working!
