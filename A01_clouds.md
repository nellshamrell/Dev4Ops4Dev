# The Cloud

Cloud is commonly seperated into 3 types of offerings:

* Infrastructure as a Service (IaaS): A hosted solution offering primatives on which to build solutions
* Platform as a Service (PaaS): A service which can accept and run code using magic
* Software as a Service (SaaS): An application in the cloud ready-to-use, typically built on IaaS or PaaS.

Today containers are asserting themselves as a possible new layer between IaaS and PaaS, 
but currently such offerings are just Docker shims running on top of existing IaaS offerings.

We will examine briefly PaaS and IaaS as potential solutions for deploying your apps.

## Platform as a Service (PaaS)

PaaS offers an easy to use, low cost solution for getting your code up and running quickly.  The
challanges of managing a full OS are removed from you and a variety of services are provided 
to allow you to control your app.  Scaling the application is typically a matter of simply increasing
the number of instances and load balancing is transparently provided for the purpose.  Additionally,
PaaS's offerings can commonly integrate with developer workflows by using Git hooks or simple
scripts to upload and run your app on the PaaS.

Several solutions exist, the most popular are:

* Heroku: Bought by Salesforce.  Supports Ruby, Java, Node.js, Scala, Clojure, Python, PHP and PERL.
* Google App Engine: Supports Python, Java & JVM Based languages, Go & PHP
* OpenShift: Created by Red Hat.  Supports Haskell, Java, JavaScript, .NET, PERL, PHP, Python, and Ruby.
* Cloud Foundry: Created by VMware, now Pivotal.  Supports Java, Ruby, Node.js, Scala, Python & PHP

While Google App Engine is the oldest and Heroku is the most popular, Cloud Foundary is picking up 
a lot of interest because its being sold and deployed by other entities as an in-house or 3rd party
PaaS.

The primary disadvantage of PaaS is its various limitations.  The same things that make it easy
to use also bind you into a certain workflow and set of capabilities that can quickly turn 
from joy to jail.

### Example of Using Heroku

```bash
$ git clone https://github.com/heroku/node-js-getting-started.git
$ cd node-js-getting-started/
$ heroku create
$ git push heroku master
$ heroku ps
=== web (1X): `node index.js`
web.1: up 2015/03/28 00:02:25 (~ 1m ago)
```

## Infrastructure as a Service (IaaS)

IaaS is all about providing primatives with which to create solutions.  Compute is typically provided
as a VM emulating a complete server OS.  This provides maximum control and flexibility.  The limitations
of IaaS are few.  Using Vagrant we can emulate the experience on workstations to ease development
and testing.

However, with power and flexibility comes cost, both in dollars and time.  Because your managing 
a full OS you'll have additional concerns around managing things like NTP, logs, monitoring, etc.
Thankfully Chef can take the bite out.

Some things to consider when evaluating various IaaS clouds are:

* Cost: Always calcuate the per-month cost of an instance, those pennies per hour look cheap at first but add up quickly
* Support: Are the friendly and fast?
* Integration & API: Consider whether or not there is a Chef Knife plugin
* Supprting Services: Many vendors provide a variety of add-on products, look particularly for monitoring and automatic backups
* Snapshot & Image Support: Images allow you to start with a pre-customized OS, snapshots allow you to more easily create images and to preform roll-backs in times of trouble, but not all support them.
* Storage Services: Storage is a complicated thing for clouds to offer, be very mindful of what SLAs and capabilities are offered by various options
* Multi-Tenancy & Size Options: When you put 10, 20, or 30 customers on a single computer there is bound to be some clashing.  Although generally controlled by the cloud provider, multi-tenancy can cause performance degredation that will adversely impact you, particularly for big databases!  Consider buying large instances in cases where performance is critical to reduce the number of neighbors.

When it comes to cloud, the elephant in the room is Amazon Web Services (AWS). The biggest 
out there, they are low cost and free-tier options, a huge community, and nearly 
any service you could desire to have (such as EC2, S3, Cloudfront, RDS, Route53, EMR, etc.)

Other notable providers include:

* Joyent
* Rackspace
* Softlayer (IBM)
* GoGrid
* Linode
* HP
* Terramark, Savvis, CenturyLink, etc.

Digital Ocean is a notable provider.  They have very limited capabilities and offerings, but what
they do offer is fast and cheap, making it ideal for development.

## A word on Containers

Docker has come to define the container concept.  Docker makes testing, development, and 
deployment a breeze.  You can fire up dozes to hundreds on your laptop and build them 
in seconds.  

Additionally, Docker creates a middle-ground between the 2 extremes of PaaS or IaaS.  In 
particular, you get the options afford by IaaS but without the hassle of managing a 
complete OS.

If you aren't using Docker today, consider doing so!

 


