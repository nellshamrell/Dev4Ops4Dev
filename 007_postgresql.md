Next, we need a database for our application.  In this workshop we're using Postgresql.

## Creating a Postgresql recipe

Let's generate a new recipe like so:

```bash
  $ chef generate recipe postgresql
```

Now we need to create the directory where our server specs will live:

```bash
  $ mkdir -p test/integration/postgresql/serverspec
```

And create the test file

```bash
  $ touch test/integration/postgresql/serverspec/postgresql_spec.rb
```

And we need to be able to access a spec_helper similar to the one living in test/integration/default/serverspec.  In this case, let's copy that one into our new integration test directory.

```bash
  $ cp test/integration/default/serverspec/spec_helper.rb test/integration/postgresql/serverspec
```

## Installing the Postgresql package

First up is installing the Postgresql package.  Let's create a couple of tests, making sure that the postgresql package is installed and that a postgres user is created (this happens automatically when the package is installed).

test/integration/postgresql/serverspec/postgresql_spec.rb
```bash
  require 'spec_helper'
  describe 'my_web_server_cookbook::postgresql' do
    describe package('postgresql') do
      it { should be_installed }
    end

    describe user('postgres') do
      it { should exist }
    end
  end
```

Then open up the .kitchen.yml file and add in the suite

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
- name: postgresql
  run_list:
    - recipe[my_web_server_cookbook::postgresql]
  attributes:
```

Then create the test instance.

```bash
  $ kitchen create postgresql-ubuntu-14-04-x64
```

And set it up:

```bash
  $ kitchen setup postgresql-ubuntu-14-04-x64
```

Now run these tests:

```bash
  $ kitchen verify postgresql-ubuntu-14-04-x64
```

And, as expected, we get failures.

Now let's make it pass.  Open up recipes/postgresql.rb and add this content:

```bash
  include_recipe 'my_web_server_cookbook::default'
  package 'postgresql'
```

Then save the file, converge, and run your tests again.

```bash
  $ kitchen converge postgresql-ubuntu-14-04-x64
```

```bash
  $ kitchen verify postgresql-ubuntu-14-04-x64
```

And they pass!

## Creating the deploy user

Next, we need to create an additional user for Postgresql called the "deploy" user.  This user will have restricted access to the database so we're not using the root user all the time.

Let's add in a test for this user.

test/integration/postgresql/serverspec/postgresql_spec.rb
```bash
  describe command('sudo -u postgres -s psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname=\'deploy\'"') do
    its(:stdout) { should match /1/ }
  end
```

Then run the test and watch it fail

```bash
  $ kitchen verify postgresql-ubuntu-14-04-x64
```

And now let's add the code to make this pass

recipes/postgresql.rb
```bash
  execute "create new postgres user" do
    user "postgres"
    command "psql -c \"create user deploy with password '#{password for node}';\""
    not_if { `sudo -u postgres psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname=\'deploy\'\" | wc -l`.chomp == "1" }
  end
```

## Granting Create DB access to the deploy user

Finally, when we deploy our application it will need to create a Postgres database.  That means the deploy user needs access to create databases.

First, a test:

test/integration/postgresql/serverspec/postgresql_spec.rb
```bash
execute "grant deploy user create db privileges" do
  user "postgres"
  command "psql -c \"ALTER USER deploy CREATEDB;\""
end
```

Now run it and watch it fail.

```bash
  $ kitchen verify postgresql-ubuntu-14-04-x64
```

Then add in the code to make it pass.
recipes/postgresql.rb
```bash
  execute "create new postgres user" do
    user "postgres"
    command "psql -c \"ALTER USER deploy CREATEDB;\""
  end
```

And we have a working Postgres database!

## Refactoring

It's working....but having the password hard coded into the recipe is not a good thing.  Let's use another development practice - refactoring.

Rather than hard coding the database password in the recipe, let's create an attributes file.  For now we'll create a defaults attributes file, but when we start deploying this to live nodes we'll use different configuration files.

First, create an attributes directory:

```bash
  $ mkdir attributes
```

Then create a file called default.rb
```bash
  $ touch attributes/default.rb
```

And open up the file and add this content:

```bash
  default['my_web_server_cookbook']['postgres_password'] = 'some_random_password_you_generate'
```

Then save and close the file.

Now let's use this in the postgresql recipe.  Open it up and modify the content so it looks like this:

```bash
  execute "create new postgres user" do
    user "postgres"
    command "psql -c \"create user deploy with password '\"#{node['my_web_server_cookbook']['postgres_password']}\"';\""
    not_if { `sudo -u postgres psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname=\'deploy\'\" | wc -l`.chomp == "1" }
  end
```

Then verify that our tests still pass by running them on a clean test kitchen instance:

```bash
  $ kitchen test postgresql-ubuntu-14-04-x64
```

