# Finding (Explicit) Application Dependencies

## Problem

Most services are far more than simply a running process listening on
a port somewhere.

When an applictation is getting ready to be deployed, you need to know
what you need to bring with you.

Some examples of things that the software DIRECTLY relies on might
include:

* persistence
  * SQL DBs - postgres, mysql, etc
  * nosql
* HTTP termination & load balancing
  * nginx / apache / etc
* messaging
  * rabbitmq, JMS
* if a public webservice...
  * memcached
  * CDNs
* Software-as-a-Service externalities
  * email transport services
  * one of many niche service that are app-domain-specific

How can the people responsible for deploying the application discover
these dependencies, make sure the list is complete, and prepare for
the deployment?

## Exercise

We have access to the source code for the application we are to
deploy, but the developers are too busy adding new features to go over
any of it with us.  What can we learn by just diving in and reading?

TODO: instructions on CD'ing to the widgetworld source code
directory, and tell them to use more, tree, etc to read.  Teams might
divide and conquer.  Individuals with some Rails should train others.

## What Happened?

Free-form discussion.  See solutions.md file for everything Clinton
gleaned. 


## Enrichment

To be covered deeply, lightly, or skipped, time allowing.

### Additional Practical Approaches

#### Conversation with developers

Developers will have a great deal of information about these
dependencies, but may have become so accustomed to them that they
don't think to mention them.  Does the fish mention the water?

Always push back to the mind of the beginner - devs will assume all
sorts of things, becuse it was setup months ago and they don't have to
think about it anymore.  Play ignorant, and keep saying things like
"So a machine running ONLY MySQL and nginx is all you need?  Just
that one machine?"

#### If configuration management code exists ...

If the project has Chef / Puppet / Ansible / etc code, dive in and read.

Two rich areas of exploration:
  
* Instance-specific information, like Chef node runlists or Ansible playbooks.
* Dependency data, like Berksfiles

#### Examine the running instances

If real instances exist, login and look around.  

* What services are running according to init.d?
* What ports are listening, according to netstat -nlp --inet? 

#### Read the applciation config files

Look for service locators / hostnames.  

Hey, they mention the RMQ hostname.  
And having a RO database host and a RW database host.  How are those synced?

#### Read the gemfiles / setup.py / npm.json

Whatever language(s) are used, they all have dependency managers.  If
the app depends on RabbitMQ, it must pull in a RMQ client library at
some point.

This can lead to some sleuthing, as many language-specific
dependencies have cutesy names.  Some are more obvious than others -
"bunny" being a RabbitMQ client - but others are rather opaque.  A
modern app may have hundred of gem/module/NPM deps, and you have no
context as to what is important or why.  It's also a major place for
cruft - things that are no longer needed are rarely removed.  Having a
developer at your side can make this process much easier.

Remember, we're not trying to manage all the library dependencies here
(that's the job of the language platform's dependency manager).
Instead, we're simply looking for evidence of dependency on an
external service.


### Other Ways to Discover Dependencies, That Only Work in Ideal Organizations 

#### Be there from the begining

Of course, the decision to pull in a SQL server, make it Postgres, and
make it 9.3, had to have ben made at some point.  In DevOps-heavy
organizations, ops engineers are present in the design meetings.  They
can help advice choices, start to plan for scaling and redundancy, and
get in front of any anti-patterns that are obvious to Ops but less so
to Dev.

So, ideally, you'd go back in time, and be at those meetings.  

Failing that, the earlier the deployers and operators can be involved
in the development process, the better.

#### Read the up-to-date, easily found, very complete design document

Some organizations believe that you can have detailed, thorough
documentation that is also perfectly up to date.  That sounds great,
but often - as schedules slip and feature pressue builds -
documentation becomes deprioritized.

By all means use any docs that you find, but bring along an
interpreter, such a developer.

#### Spend a day with a developer setting up an environment

Using screen sharing or physical desk sharing, "peer program" the
experience of going from (your equivalent of) bare metal to a running,
working application.  This will reveal many deltas from the "official
plan," and may

This can be very productive under ideal conditiions, but requires some
things that may be non-starters:

* Setting up an environment may be an undocumented, multi-day affair
* Developers may not set them up consistently - one uses Vagrant/VirtualBox, one uses direct execution on the local machine, one uses AWS.
* The Dev environment may have toy implementations:
  * sqlite instead of postgres
  * WEBrick instead of a real webserver
  * etc
* getting a developer's time away from feature work may not be politically possible
