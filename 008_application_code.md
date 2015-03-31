# Deploying the Application Code

## A Bit of House-Keeping - Organizing Recipes

### Why do we have a default recipe?

The "default' recipe is used when specific recipe is mentioned.
Because of this, it is often used as a convenient entry point to a
larger cookbook.  

So, many cookbooks place their subsystem-specific code in
recipes, and have the main default recipe simply call out to them.

Looking at our default recipe, we see it contains code to refresh the
APT cache, and then code to setup apache.  Let's move the apache code,
so our default recipe will be more generic.

#### Copying the Code

There are several ways to copy the Apache code.  One way is to copy the
entire default.rb file, then trim out lines that don't apply.

```bash
  vagrant@workshop my-cookbook $ cp recipes/default.rb recipes/apache.rb
  vagrant@workshop my-cookbook $ vim recipes/apache.rb
# Delete everything but:
package 'apache2'

service 'apache2' do
  action [:start, :enable]
end

template '/etc/apache2/apache2.conf' do
  source 'apache2.conf.erb'
end

  vagrant@workshop my-cookbook $ git add recipes/apache.rb
```

#### Arranging to have it included

Next, we need to edit the default recipe to tell it to include the
contents of the new apache recipe - and remove the old code!

```bash
  vagrant@workshop my-cookbook $ vim recipes/default.rb

# Delete the apache-related code

# Add this line:
include_recipe('apache')
#----
  vagrant@workshop my-cookbook $ git add recipes/default.rb
  vagrant@workshop my-cookbook $ kitchen TODO
  vagrant@workshop my-cookbook $ git commit -m "Move apache code \
  to its own recipe"
```

TODO - check for test kitchen runlist changes

### Including the other recipes in Order

Now that we have a clean default recipe, let's make it so running
the default recipe fully sets up and runs the application.

```bash
  vagrant@workshop my-cookbook $ vim recipes/default.rb

# Add these lines:

include_recipe('ruby')
include_recipe('postgresql')
include_recipe('apache')
include_recipe('passenger')

#----
  vagrant@workshop my-cookbook $ git add recipes/default.rb
  vagrant@workshop my-cookbook $ kitchen test # note this does a full cycle
  vagrant@workshop my-cookbook $ git commit -m "Make default recipe\
  call all subcomponents"
```



## Adding a Recipe To Send the Code

At this point, we're now ready to add a recipe that will actually sent
the code to the nodes.

### Adding an empty recipe

Let's make a new recipe, called send-the-code.rb, and include it in
the default recipe.

```bash
  vagrant@workshop my-cookbook $ echo '# TODO' > recipes/send-the-code.rb
  vagrant@workshop my-cookbook $ git add recipes/send-the-code.rb
  vagrant@workshop my-cookbook $ vim recipes/default.rb

# Add these lines:

include_recipe('passenger') # existing
include_recipe('send-the-code')

#----
  vagrant@workshop my-cookbook $ git add recipes/default.rb
  vagrant@workshop my-cookbook $ git commit -m "Add an empty
  send-the-code recipe"
```

### TDD RED - Looking for the Code

Now let's add a Kitchen scenario for just testing placement of the
code.  This should be familiar by now, so we'll go through it
quickly.

```bash
  vagrant@workshop my-cookbook $ mkdir -p test/integration/send-code/serverspec
  vagrant@workshop my-cookbook $ cp test/integration/default/serverspec/spec_helper.rb test/integration/send-code/serverspec
  vagrant@workshop my-cookbook $ git add test/integration/send-code/serverspec/spec_helper.rb
  vagrant@workshop my-cookbook $ git commit -m "Standard spec-helper for the send-code recipe"
  vagrant@workshop my-cookbook $ vim test/integration/send-code/serverspec/send-code_spec.rb
```

Within the test file, let's just check for the main controller file.

```ruby
require 'spec_helper'
describe 'my_web_server_cookbook::send-code' do
  describe package('/var/www/app/controllers/widgets_controller.rb') do # TODO Location
    it { should be_a_file }
  end
end
```

And edit .kitchen.yml to add a test suite:

```yaml

  - name: send-code
    run_list:
      - recipe[send-code]
```

Run it to verify a red result.

```bash
  vagrant@workshop my-cookbook $ kitchen verify send-code-ubuntu-14-04-x64
  # should be RED
  vagrant@workshop my-cookbook $ git add .kitchen.yml test/integration/send-code/serverspec/send-code_spec.rb
  vagrant@workshop my-cookbook $ git commit -m "TDD RED: send code and look for controller file"
```

### TDD Green - Shipping the Code

So, now we're ready to implement!  There are many ways to send code.  We could:

  * Put the code in the chef repo, and sync them as files 
  * Make a tarball, and make resources to fetch and untar it
  * Use an artifact server
  * Use a remote deployment system like Capistrano
  * If the code is in git, using the 'git' resource might be simplest

It so happens that the code IS in git, because you forked Nell's widgetworld repo.  Let's use the git resource.

Edit recipes/send-code.rb

```ruby

git 'Install widgetworld via git' do
    action :checkout
    destination '/var/www'
    repository 'https://github.com/YOURUSERNAME/widgetworld.git'
end

```

#### What, no git?

It failed for me, emitting

```bash
    STDERR: sh: 1: git: not found
```

Fair enough; if we're going to use git to check something out, we should probably ensure that git is installed.

Since we're installing OS packages, we need to add the apt recipe to the runlist.

Edit .kitchen.yml :

```yaml

  - name: send-code
    run_list:
      - recipe[apt]       #    <---  Add this line
      - recipe[send-code]
```

Edit recipes/send-app.rb, and add (prior to the git resource)

```ruby
  package 'git'
```

Run again, and it should be green.

```bash
  vagrant@workshop my-cookbook $ kitchen verify send-code-ubuntu-14-04-x64
  vagrant@workshop my-cookbook $ git add .kitchen.yml recipes/send-code.rb
  vagrant@workshop my-cookbook $ git commit -m "TDD Green on code deploy using git resource"
```


