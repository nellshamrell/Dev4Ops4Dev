# Creating a Deploy User with Chef

It's generally not a good idea to give an application root access to your machine when it is deploying.  In the section of the workshop we will create a new "deploy" user that Capistrano (our deployment tool) can use to deploy to our VM.

## Creating a User recipe

Let's generate a new recipe like so:

```bash
  vagrant@workshop $ chef generate recipe user
```

Now we need to create the directory where our server specs will live:

```bash
  vagrant@workshop $ mkdir -p test/integration/user/serverspec
```

And create the test file

```bash
  vagrant@workshop $ touch test/integration/user/serverspec/user_spec.rb
```

And we need to be able to access a spec_helper similar to the one living in test/integration/default/serverspec.  In this case, let's copy that one into our new integration test directory.

```bash
  vagrant@workshop $ cp test/integration/default/serverspec/spec_helper.rb test/integration/user/serverspec
```

## Creating a deploy user

As always, we start with a test:

test/integration/user/serverspec/user_spec.rb
```bash
require 'spec_helper'
describe 'my_web_server_cookbook::user' do
  describe command('cut -d: -f1 /etc/passwd') do
    its(:stdout) { should match /deploy/ }
  end
end
```

Now add this suite to your .kitchen.yml file:
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
- name: user
  run_list:
    - recipe[my_web_server_cookbook::user]
  attributes:
```

Then create the test instance.

```bash
  vagrant@workshop $ kitchen create user-ubuntu-14-04-x64
```

And set it up:

```bash
  vagrant@workshop $ kitchen setup user-ubuntu-14-04-x64
```

Now run these tests:

```bash
  vagrant@workshop $ kitchen verify user-ubuntu-14-04-x64
```

And, as expected, we get a failure.

Now let's write the code to make it pass.

Add this to your recipes/user.rb file

```bash
  execute 'add deploy user' do
    command "sudo adduser deploy"
    action :run
    not_if "grep deploy /etc/passwd", :user => "deploy"
  end
```

Now converge the code

```bash
 vagrant@workshop $ kitchen converge user-ubuntu-14-04-x64
```

And run the test again

```bash
   vagrant@workshop $ kitchen verify user-ubuntu-14-04-x64
```

And it passes!

## Adding the deploy user to the sudoers group

The deploy user needs to be able to run sudo commands.  To do this, we need to add it to the sudoers group.

Add this to your test file

test/integration/user/serverspec/user_spec.rb
```bash
   describe command('getent group sudo') do
     its(:stdout) { should match /deploy/ }
   end
```

Now run your tests:

```bash
  vagrant@workshop $ kitchen verify user-ubuntu-14-04-x64
```

And we get the expected failure.

Now add this code to recipes/user.rb to make it pass.

```bash
  execute 'add deploy user' do
    command "sudo adduser deploy sudo"
    action :run
    not_if "getent group sudo | grep deploy"
  end
```

And it passes!

## Allowing the deploy user to sudo without being prompted for a password

Finally, it can be annoying to be prompted for a password every time the deploy user uses sudo, particularly if they are used to connecting via SSH.  Let's remove this password prompt,we do this by creating a file at /etc/sudoers.d/deploy.

First, some tests to make sure the file exists, then another to ensure the correct content is in the file:

test/integration/user/serverspec/user_spec.rb
```bash
  describe file('/etc/sudoers.d/deploy') do
    it { should be_file }
  end

  describe command('cat /etc/sudoers.d/deploy') do
    its(:stdout) { should match /deploy ALL=\(ALL\) NOPASSWD:ALL/ }
  end
```

Now run the tests and watch them fail.

```bash
  vagrant@workshop $ kitchen verify user-ubuntu-14-04-x64
```

Now let's make it pass:

First, we need to create a template for this file, remember you need to run the generate command from your my_web_server_chef_repo directory.

```bash
  vagrant@workshop $ cd ~/my_web_server_chef_repo
```

```bash
  vagrant@workshop $ chef generate template cookbooks/my_web_server_cookbook deploy
```

Now change directories back to your cookbook directory:

```bash
  vagrant@workshop $ cd cookbooks/my_web_server_cookbook
```

And open up the template file and add this content.
templates/default/deploy.erb
```bash
  deploy ALL=(ALL) NOPASSWD:ALL
```

Then save and close the file.

Now add this to your recipe file to call the template
recipe/user.rb
```bash
  template '/etc/sudoers.d/deploy' do
    source 'deploy.erb'
  end
```

Now converge the code:

```bash
  vagrant@workshop $ kitchen converge user-ubuntu-14-04-x64
```

And run the tests:

```bash
  vagrant@workshop $ kitchen verify user-ubuntu-14-04-x64
```

And they should pass!
