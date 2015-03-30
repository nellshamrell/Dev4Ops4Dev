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

### TDD RED - What do we expect?

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



