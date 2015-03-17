# Solutions for Finding Explicit Dependencies

What can you learn by examining the source code of the Widgetworld app?

## From app README.rdoc:

* Rails
* PostgreSQL

## From app Gemfile:

* a Rails/Ruby environment, no runtime version constraint
* Postresql client library (pg)
* a Rack-compatible server
  * may have preference for unicorn
* may have support for Capistrano deployment

## From Rakefile + lib/tasks...

* No custom DB seed task.  Must be using migrations?
* Found schema, seeds, and migration in db/

## From config/database.yml

* PG version contraint is 8.2+, which is super-generous
* Configured with the author's name as username
* No default password provided in config file.  Advised instead to provide a env variable: DATABASE_URL or WIDGETWORLD_DATABASE_PASSWORD
* Appears to expect local-machine (IPC socket) database for any env less than prod

## From configure/application.rb:

* May want system time to be UTC

## Any deployment or config management code?

Despite commented-out mention of capistrano in Gemfile, no apparent deployment or config management code.  We're on our own!

