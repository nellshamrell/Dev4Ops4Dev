# Finding IMPLICIT app dependencies

All the stuff no one thought of when they were writing the app on their desktop, but will be needed when running it in the real world.

## Problem

So, now you know what the app needs to run, according to the box it
came in.  But is that really everything?

## Exercise

What else is needed to live with the app in production?

Assume you are deploying to DigitalOcean.  What
else do you need - services, plans, and configuration - to stand up the systems?


Try thinking a bit about these abilities:

* Accessible
* Available
* Deployable
* Diagnosable
* Monitorable
* Promotable
* Recoverable
* Scalable
* Securable
* Testable


## Discussion

What did we identify as certainly missing?

What is missing in apps at your day job?  When are these gaps discovered?

What will we have time to cover today?

## Enrichment

### Meet The Ables

A well-behaved application has these abilities:

* Accessible
* Available
* Deployable
* Diagnosable
* Monitorable
* Promotable
* Recoverable
* Scalable
* Securable
* Testable

PRO TIP: To remember these, remember, if the app isn't
operationalized, you'll be RAD, MAD PSST!

#### Accessible

You, or your automated minions, need a way in. 

* If in a cloud, API/console access.  For AWS, who manages IAM users?
* SSH access.  Are you managing keys on a shared account?  You're not sharing keys, right?
* Are you using some kind of central identity management, like LDAP?
* What do the Network ACLs / Firewalls / Security Groups look like? Who manages them?  Do you need a private VPN tunnel onto the management subnet?
* What about network interconnects for the app itself (database to app server, etc)
* Does any of this have to be audited for PCI, SOX, PII, HIPAA?

#### Available

If something breaks, you need to have a plan for how the system
absorbs the shock.  

* What parts are likely to break or disappear?
* Which parts of the design are single points of failure?  Can you make them redundant?  At a justifiable cost?
* Determine the failure domains of your hosting provider.  These might be called Availability Zones, racks, circuits, or something else.  Which parts of your app should be contained in one FD?  Which parts should span FDs?  Search for hidden dependencies!
* How will you test your availability solutions?  Google "simian army" for ideas.

#### Deployable

Getting the thing setup for the first time, and rolling out new versions, can be really complicated.  Automation can be help here.

* What is your approach?  Are you shipping containers, or are you building each node using configuration mangement software like Chef?  If you are shipping containers, how are you building them?
* Do you always create new machines and deploy to them, or do you perform "upgrades" on existing machines to roll out new code?  
* How will you handle state - persistent business data, like the contents of databases?
* How will you handle schema changes in databases? (no one seems to be good at this yet)
* Does the app use "feature flags"?  How will you toggle them?
* How will you orchestrate things like service restarts?  Adding and removing members from a load balancer?

#### Diagnosable

Depending on the security policy, developers may or may not be permitted direct access to production instances.  If an application outage occurs, the developers will likely be the best people to fix the issue.

* How will logs from the instances be collected, retained, and made searchable?
* HOw will sensitive data be identified and removed from logstreams?
* Is it easy for developers to add instrumentation to the application?  Does it require a code push, or can it be done ad-hoc during an incident?
* Is relying on an external APM SaaS vendor like NewRelic or AppDynamics acceptable?
* Can you get the same instrumentation mechanisms in dev as in prod?  Can you turn off expensive metrics on a per-env basis?

#### Monitorable

Tying into the one above, you'll want to keep an eye on some of the mterics you collect, and alert on them.

* Are failure modes of the application known, or is this all new?
* The metrics people think of first - CPU, disk, memory - may not even be meaningful in the cloud.  Try to model the monitoring as "what business events make us money, and how can we detect an anomaly in them?"
* Once you have an idea for business monitoring, you can start thinking of how to build up metrics from probes into middelware: a SQL query to count revenue / hour, a RMQ check to watch for workers failing to keep up with requests, etc.
* Did the developers make it easy or hard to expose these things?  Is there an instrumentation API?

#### Promotable

You need to be able to clearly know which version of the code is in each environment in the path to production.  In some places, that might just be "Dev" and "Prod", but there may be many, with branching paths.

* Do you need to be able to deploy any version of the application to any environment at any time?  Can any of that be relaxed to make your life easier?
* Is there an artifact server, like CodeStation or Artifactory, available?
* Are the developers packaging the code as a versioned OS package?  Could you?
* Is it sensible to deploy directly from the version control system?
* Do you have production constraints, like "prod may only pull from upstream; a prod deploy can never be initiated from an upstream env"?
* What mechanism will do the actual deploy - Deployinator, or similar?
* Are you expected to rollback, or roll forward?

#### Recoverable

In the event of a disaster, can business operations resume?

* What kind of disaster?
  * Hacked!
  * Datacenter full of snakes with sudo
  * Teensy bug in application that deletes all the data, backup system faithfully follows suit
* How long can you tolerate before data is restored?
* How much data can be outright lost?
* How often will you drill your recovery procedure?
* How does your retention policy play ball with regulatory constraints (PCI, SOX, HIPAA, EU....)

#### Scalable

If the business grows suddenly, can the system grow to match?

* How automatic should the autoscaling be?  How would you detect a surge event?
* Do you plan to reserve instances?
* What if it shrinks? 
* Can you predict cost?

#### Securable

How do you manage the real risks to the business without impeding the staff's ability to make changes?
* What's a "real" risk, anyway?  Whose idea of risk are we dealing with?  Will there be 3rd party scans?
* Do you have objectivity here?
* What are the egress and ingress points?  Can the app de decomposed into tiers?  which middleware parts need to speak to which other parts?
* SSL thruought?  Still trust SSL?
* How often will you rotate passowrds, keys, etc?  How will you do that without locking yourself or others out?

#### Testable

Po one's nerfect, and mistakes are bound to happen.  How do we catch them as early as possible?
* Is there a code testing setup (CI server)?  Can ops use it?
* If infrastructure is code, and code should be tested, are you going to test the infrasructure?  How will you do that?
* How will you mock 3rd party services?
* Ephermeral testing is one thing, how will you do longevity testing?
* Can you do canary testin during deployment?

