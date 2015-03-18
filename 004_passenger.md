Although Apache works out of the box for some web applications, it does not support Ruby by default.  To serve up a Ruby on Rails application we need an application server in order to make it work.

This tutorial will focus on using [Phusion Passenger](https://www.phusionpassenger.com/).

For an excellent and in depth explanation of the different between a Web Server like Apache and an application server like Passenger, see this fantastic [explanation on Stack Overflow](http://stackoverflow.com/a/4113570).

## Creating a Passenger recipe

Let's generate a new recipe like so:

```bash
  $ chef generate recipe passenger
```

## Test Drive Installing Passenger with Chef

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

```bash
  gem_package 'passenger' do
    action :install
  end
```

