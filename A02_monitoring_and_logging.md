# Monitoring & Logging

Operations is all about the care and feeding of applications, especially after they
are deployed.  Two of the most fundamental concerns are monitoring and logging.

## Monitoring & Alerting

Monitoring is at the heart of Operations.  The most fundamental responsibility
of operations is to keep the service up.  But it is also true that "just because
its up doesn't mean its working."  There are several layers to consider
in monitoring.  

First, the most basic monitoring of the service as a whole:

1. Service Availability: Is the service accepting and processing requests?
2. Service Response Time: Are requests being responded to in an acceptible length of time?

Second, we monitor the individual parts of the service:

3. Node Availability: Are each of the systems up?
4. Node Component Availability: Are the services that each node providing actually responding?

Third, we drill down into the basic health of the underlying nodes:

5. Node Capacity & Utilization: Monitoring disk, memory, and processor utilization

Rest assured, we can get much more fine-grained than this.  The more detailed our monitoring
the faster it will be to troubleshoot and respond to incidents.

For a very detailed discussion of troubleshooting methodologies which can be the foundation
upon which comprehensive monitoring checks are created, see Brendan Gregg's "The USE Method".
(http://www.brendangregg.com/usemethod.html)

### Monitoring Solutions

There are several monitoring solutions available today, but its important to realize that
not all solutions traverse the layers we outlined above.  For instance, your IaaS or PaaS 
cloud may provide instance monitoring, but that data will at best cover node level details.
Cloud instance monitoring typically gathers information from the underlying VM, not the running
OS.

For in-house or private monitoring popular solutions include:

* Nagios: The worlds worst monitoring platform, almost exclusively based on "good" or "bad" checks.
* Zabbix: Very flexible solution providing integrated trending and an extensive agent.
* Zenoss: An easy-to-use solution which is very pretty but limited in capabilities.
* Sensu: Extremely customizable MQ based monitoring framework

SaaS alternatives include:

* ServerDensity: Agent based monitoring
* DataDog: Powerful event management solution which includes agent based monitoring.

For meta-monitoring of service availability and performance, particularly of web services, include:

* Pingdom: Distributed up/down monitoring of web services, including scripted sessions
* StatusCake: Pingdom alternative
* New Relic: A web performance monitoring and measurement service
* etc.

### Agent Based vs Remote Monitoring

Monitoring solutions can broadly be divided into two camps: those which can or do rely on
an agent to be installed on the host and those which don't.  

Historically, systems were monitored via the Simple Network Monitoring Protocol (SNMP) allowing
monitoring without the need for an 3rd party software, however the "Simple Protocol" was anything
but simple and has fallen out of use for all but appliances on which agents can not be installed.

Some monitoring systems can use SSH to connect to a host to preform a checks.  While this may
be very convient it is both slow and resource consuming as well as causing a variety of 
security related problems (namely, filling up your audit logs with garbage).

As noted earlier, cloud providers often can provide resource monitoring for your instances.  
This monitoring typically doesn't require an OS agent because the metrics are pulled from the
underlying virtual machine (VM), however this limits significantly what can be monitored.

Agent based monitoring is the most powerful but incurs the overhead of an additional process
and hassle of installing the agent.  Despite this, your dillegance will be rewarded by 
a full featured and customizable set of monitoring checks.  Many systems provide a single small
agent with a simple configuration file, however others (namely Nagios's NPRE) consist of a 
library of scripts which call yet other scripts to gather data and report status.  

### Computed vs Status Based Checks

Agent based systems typically invoke a shell command and report based on the exit status.
If the return code is 0 the check is "OK" otherwise something is wrong.  Interpretation of
the code differs based on solution.  The shell command invoked is usually, especially for Nagios,
a script which preforms logic and exits appropriately based on the status.  Additionally,
data can be returned to the server to provide specific metrics, such as percentage of disk used.

In systems such as Zabbix, complex "triggers" can be created on the server which trigger 
alarms based on a computed formula.  An example is to only raise an alarm if CPU has been 100%
for 30 minutes.

### OS Monitoring Considerations

When monitoring a host OS, consider monitoring the following basics:

* Load Average (Grain of salt)
* Disk Free Percentage for each mount
* Free RAM (Be careful with this)
* VM Swapping 
* Uptime less than x minutes (reboot detection)
* Critical processes running (SSH, your app, your database, etc)

In addition to what is monitored, the interval at which you are polling matters as well.
If you're checking too infrequently you may miss events.  If you're checking too frequently
you may overwhelm your monitoring system or steal host resources from your applications.

Finding the right mix of checks and frequency can take time.

### Alerting

All the checks in the world won't help you if you don't know an alert has fired.  All monitoring
solutions include the ability to send email when an alert is encountered.   Many also include 
a flexible method of sending the alert to a plugin script which can preform any action you wish.

If your organization uses a chat system, such as Jabber, HipChat or Slack, you should consider
finding a plugin to send alerts to you directly (PM) or to a room where the appropriate people 
will see it.

When not on duty its up to our trusty cell phones to act as pagers.  PagerDuty is by far
the most common solution for paging.  PagerDuty provides the ability to create "Services"
to which you associate escalation rules ("If alarm isn't acknowledged in 5 minutes, escalate to
person X") and create on-call rotations based on a schedule.  PagerDuty can be alerted to
via their API or by sending email to a special email address associated with each service.
Finally, PagerDuty includes the ability to "page" via Phone, SMS, or their mobile applications.

A final word about PagerDuty, most monitoring tools include a variety of features
for handling escalations, sending SMS, handling vacations or scheduling the on-call person,
however when you have multiple solutins, keeping all of them up-to-date can be very difficult.
By sending all alerts to PagerDuty you can have a single place for managing your on-call
alerting.

### Exercise: Monitoring with Pingdom, Server Density & PagerDuty

All 3 services provide free trial accounts.  

Signup for Pingdom first, create a check for your web service.  

Next signup for PagerDuty.  Create a service for your web-app.  Get the email
address for the service and add it to Pingdom.  

Finally, signup for a ServerDensity trial and use its PagerDuty integration.  Download
the agent and deploy.  A cookbook for ServerDensity can be found in the Chef Supermarket!

## Trending

Just a word about trending.  Monitoring & Alerting are about notifying you when undesirable events
occur to which you should respond.  This is inherently a reactive pattern.

In order to inspect our application and detect behavior proactively we need to be gathering metrics
and visualizing them.  This is frequently done by a solution independing of your monitoring and
refered to as "trending".  

There are countless solutions available, but some include:

* SaaS: Librato, Circonus, Datadog, etc.
* Open Source: Graphite, InFluxDB & Grafana, OpenTSDB, etc.
* Web App Performance: New Relic, Appneta, etc.

Good trending will allow you to make data-driven decisions, perform capacity planning, 
spot performance issues, and much more.  Ultimately key metrics should be visualized 
on a dashboard for all to consume.

## Logging

On a given node there are a variety of logs being produced, such as:

* System Logs (*/var/log/syslog*, */var/log/dmesg*, etc.)
* Access Logs (*/var/log/auth.log*, */var/log/wtmp*, etc.)
* Package Administration Logs (*/var/log/dpkg.log* and */var/log/apt/*)
* Chef Logs (*/var/log/chef/*)
* Firewall Logs (*/var/log/ufw.log*, etc.)
* Database Logs (*/var/log/postgresql/*, etc.)
* Web Server Logs
* etc, etc, etc.

There are three initial concerns we have with logs:

1. Identify those logs which are pertinant to ongoing operation
2. Enable or Tune Log Rotation for those logs
3. Centralize logs for safety and ease of use

Lets talk about these in turn.

### Identifying Pertinant Logs

It sounds very responsible and easy to simply care about all logs, but not all
logs are created equal.  Web server logs generally give us a wealth of information
about our users and our application and are extremely valuable.  Firewall logs
on the other hand seem extremely useful but depending on how your logging rules
the logs can become huge very quickly, often with duplicate information which
needlessly consumes resources.

Therefore, its important to examine our logs, understand the behavior, tune 
logging parameters on an application specific basis (firewalls for instance),
and then standardize those tunings in our cookbooks.

Always be sure to re-review your choices over time as your architecture evolves!

### Log Rotation

All UNIX varients ship with some form of log rotation utility, Linux typically uses
the boringly named _logrotate_.  The config file for _logrotate_ can be found in 
*/etc/logrotate.conf* and */etc/logrotate.d/*.  Lets look at an example log rotation
configuration for Chef:

```
/var/log/chef/client.log {
  rotate 12
  weekly
  compress
  postrotate
        /usr/sbin/invoke-rc.d  chef-client restart > /dev/null
  endscript
}
```

This configuration says that we should watch the */var/log/chef/client.log* log
file (which is being written to by _chef-client_, naturally).  When we rotate
we want to keep the 12 most recent files.  We will rotate weekly and compress the
file after rotation.  We also include a "postrotate* command which restarts
_chef-client_, which is a common pattern for rotation because the running app is now 
going to write to a file that was just rotated (mv operation by default), so it
needs to be restarted to keep logging properly.  It is also possible to specify a 
"copytruncate" directive which will copy the log file and then truncate (destroy the
contents of the origonal), which is useful for some older applications to avoid restarting
the log, but please note that this works well for some applications and not other
based on whether or not the file is being kept open and appended too.

Logrotate includes a wide variety of additional directives to suite your needs, most
notably the "size" directive which will rotate based on file size rather than time.

If we look at our Chef Logs directory we'll see that logrotate has been hard at work:

```
root@magnolia:/var/log/chef# ls -lh
total 260K
-rw-r--r-- 1 root root  44K Mar 29 23:23 client.log
-rw-r--r-- 1 root root  17K Jan 25 07:53 client.log.10.gz
-rw-r--r-- 1 root root  17K Jan 18 07:20 client.log.11.gz
-rw-r--r-- 1 root root  14K Jan 11 07:23 client.log.12.gz
-rw-r--r-- 1 root root  17K Mar 29 07:37 client.log.1.gz
-rw-r--r-- 1 root root  17K Mar 22 07:26 client.log.2.gz
-rw-r--r-- 1 root root  17K Mar 15 07:31 client.log.3.gz
-rw-r--r-- 1 root root  12K Mar  8 07:36 client.log.4.gz
-rw-r--r-- 1 root root 6.2K Mar  3 07:34 client.log.5.gz
-rw-r--r-- 1 root root  19K Feb 23 07:28 client.log.6.gz
-rw-r--r-- 1 root root  17K Feb 15 07:36 client.log.7.gz
-rw-r--r-- 1 root root  14K Feb  8 07:11 client.log.8.gz
-rw-r--r-- 1 root root  19K Feb  2 07:33 client.log.9.gz
```

Remember to watch your logs grow over time and consider the disk they 
are consuming.  Based on the growth and your storage constraints tweek 
the rotation rules to avoid running your node out of disk.  (This is
one of the most common causes of failure!)

### Centralizing Logs

Logs should be centralized for several reasons: 

* If the node ever dies we've lost them.  
* If we are properly rotating our logs they won't be around for long, if we realize something happened in the past and want to investigate we may not be able to.  
* If we have multiple nodes we'll generally want to aggregate the logs together, namely web logs
* Most importantly, modern log analytics provides a wealth of features and capabilities which allow us to use log data in novel ways

Traditionally logs would be transported using the purpose built "syslog" facility
which is typically a standard service provided with any OS (UNIX in particular).
syslog is written to via kernel syscall and then a user-land daemon (_syslogd_)
would route the incoming "messages" to a local file or a remote syslog server, or both.
The most popular syslog implementations for Linux are *syslog-ng* and *rsyslog*.
 
Today developers are using the syslog facility less and less, opting instead to 
write directly into files.  As a result, syslog implementations have been enhanced
to read from a variety of sources, including local files.  Also, many logging 
solutions offer their own *collectors* or *relays* for transporting logs on their own.

### Log Formats

Traditionally, logs have been generated by _printf()_ and therefore formated in a predictable 
pattern, one event per line.  However in our modern world filled with languages eager to 
dump massive exception stack-traces into our log files this caused processing problems.  
The solution came with the rise of JSON as a general purpose serialization format.  It also
allows for more detailed and "schema-free" messages to be put into a single log file.

Here is an example of a traditional Apache Web Log:

```
110.82.178.33 - - [30/Mar/2015:07:30:06 +0000] "GET /tamr/ HTTP/1.1" 200 428007 "http://www.cuddletech.com/tamr/" "Mozilla/5.0 (Windows NT 6.1; rv:26.0) Gecko/20100101 Firefox/26.0"
```

Here is an example of a JSON formated log:

```
{
    "version": "1.0",
    "host": "product-api0",
    "timestamp": 1324936418.221,
    "short_message": "Something is wrong",
    "full_message": null,
    "level": 7,
    "facility": "myapp.api.handler",
    "_accountId": "ac42",
    "_txnId": ".rh-3dT5.h-product-api0.r-pVDF7IRM.c-0.ts-1324936588828.v-062c3d0"
}
```

JSON is clearly a better log format, and much easier for developers but this created
a problem for SysAdmins: log transport, processing and analysis tools preform line-processing!
Thankfully over the last 2 years most popular tools have been updated to 
support JSON and this is no longer a significant barrier.  Even *rsyslog* and *syslog-ng* 
now include JSON support.

### Logging Solutions

A wide variety of solutions exist for logging, some of them include:

* On-Prem Free-standing: Splunk, LogLogic, LogRhythm, etc. (Many have a security focus and called "Security Incident & Event Management" (SIEM) solutions, but can be used for general purpose)
* SaaS: Sumologic, PaperTrail, Loggly, etc.
* Transports & Routers: Fluentd, Logstash, Apache Flume, Scribe, Chukwa, etc.

Today there are 3 dominant solutions depending on your use-case:

Splunk is dominant for in-house/on-prem installations.  SumoLogic is dominant for cloud 
based deployments.  Both solutions includes rich search and analysis capabilities, 
collectors and aggregators for transport, plus graphing, alerting, etc.

In the Open Source space the rage today is the ELK stack, the combination of 3 seperate peices of software:

1. ElasticSearch for storage and search
2. LogStash for processing, manipulation, and transport
3. Kibana, a beautiful single-page-app for searching and visualizing logs stored in ElasticSearch.

While the ELK stack is "free", there is tremendous complexity in scaling the solution and many 
of the feaures found in commercial solutions (such as saved search, report generation, alerting, etc)
must be created yourself which consumes staff time.

### Exercise: SumoLogic

Go to www.sumologic.com and create a free account.  Once signed up you can choose to accept
logs from a transport like Syslog, Fluentd, or Logstash, or alternatively you can download 
a collector for your platform.

Download and install a collector for your platform.  Then using the SumoLogic UI, configure
the logs you wish to collect.  Start by adding a web server log.

Once data has started to flow into the system, try some test searches based on browser type.
Try creating alerts which will email you when certain URLs are accessed, or use the SumoLogic
"LogReduce" feature to get a comprehensive overview of your logfiles.

A Chef cookbook exists for SumoLogic, find it on the SuperMarket!





