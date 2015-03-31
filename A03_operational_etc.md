# Other Operational Concerns

The care and feeding of a healthy application and especially the environment in which
it thrives is complex and multi-fascited.  Here we'll touch on a variety of different
topics, including:

* DNS & Name Registrars
* SSL & CAs
* CDNs
* Caching
* Load Balancers
* SLAs
* Incident & Change Management
* Post Mortems & Retrospectives

## DNS & Name Regristrars

There is a truism in Operations teams: "Everything is a DNS problem."  Name resolution
is indeed the cause much of the worlds suffering, not nessiarily because of DNS itself
but because the world relies so heavily on it that if its not accessible for some reason
the entire world seems to be broken.

Domains can be purchased easily from a variety of venders.  Register.com and GoDaddy
were very popular in the past but have fallen out of favor.  NameCheap is one of the
favorite solutions today.

When registering a domain be very careful to specify your contact information accurately!
Initially you may be inclined to enter less personal data or distort information for
privacy sake, however many other services will validate your owners claims against
what is returned by the WHOIS database:

```bash
$ whois cuddletech.com

Whois Server Version 2.0

Domain names in the .com and .net domains can now be registered
with many different competing registrars. Go to http://www.internic.net
for detailed information.

   Domain Name: CUDDLETECH.COM
   Registrar: NETWORK SOLUTIONS, LLC.
   Sponsoring Registrar IANA ID: 2
   Whois Server: whois.networksolutions.com
   Referral URL: http://networksolutions.com
   Name Server: NS-1362.AWSDNS-42.ORG
   Name Server: NS-1759.AWSDNS-27.CO.UK
   Name Server: NS-404.AWSDNS-50.COM
   Name Server: NS-624.AWSDNS-14.NET
   Status: clientTransferProhibited http://www.icann.org/epp#clientTransferProhibited
   Updated Date: 10-dec-2014
   Creation Date: 30-jan-1999
   Expiration Date: 30-jan-2017

>>> Last update of whois database: Mon, 30 Mar 2015 19:42:32 GMT <<<
Registry Registrant ID:
Registrant Name: Rockwood, Ben
Registrant Organization:
Registrant Street: 4544 Santa Cruz Ct
Registrant City: Fremont
Registrant State/Province: CA
Registrant Postal Code: 94536
Registrant Country: US
Registrant Phone: +1.5107957347
Registrant Phone Ext:
Registrant Fax: +1.7074479503
Registrant Fax Ext:
Registrant Email: benr@gmail.com
...
```

SSL Certificates are only issued after the Certificate Authority (CA) validates
your ownership.  This is normally done by simply sending email to the domain
or the registrant email.

## SSL & CAs

Secure Socket Layer (SSL) is a common method of encrypting communication, particularly
web communication.  SSL utilizes RSA Key Pairs consisting of a private and public key.
For web servers the private key is stored on your web server and the public key is
openly distributed.  While key pairs are useful, we aren't just interested in encrypting
traffic, rather we want assurances that the thing we're communicating to is in fact
what we think it is.  Therefore we introduce "key signing".   

When you want to secure your web service via SSL you will create a key pair and then
create a "Certificate Signing Request" (CSR).  This CSR is your public key with additional
metadata describing your organization and the URL of the thing you are securing (the Common 
Name, or CN).  The CSR is then sent to a Certificate Authority (CA) which signs the CSR 
(for a fee of course), after validating that you as an organization are in fact the 
one described in the CSR, the CSR is signed by the CA and returned to you as an SSL Certificate.
The SSL Certificate and Private key are then loaded onto your web server.

When HTTPS clients connect to your web server, they will be given the SSL Certificate
and your browser will check it against a set of locally stored CA certificates (which ship
with your browser).  If the certificate checks out and matches the thing your connecting to
the encrypted communication proceeds.

In order for your browser (or HTTP client) to work as you expect it is neccisary that your 
certificate is signed by a CA that is included in the certificate bundle shipped by the 
major browsers.  This means that your options are somewhat limited and the CA's can 
charge a lot of money for signing.  Commonly used CA's include Verisign, Digicert, 
Thawte, RapidSSL, GeoTrust, Commodo, etc.  There is even StartSSL which can provide
free SSL certificates for individuals.  Please note that when you create an account with 
a CA to issue keys they will require you to validate your authority to issue SSL Certificates
on behalf of your organization, which can take a while.  For simple validations they
will send email to a common email addres, such as "hostmaster@yourdomain.com", for 
extended validations (to get that green SSL bar in your browser) you'll need "Extended
Validation" (EV) which requires supplying detailed and private information about your 
organization such as your Dun & Bradstreet Number (DUNS).

SSL Certs are typically purchased for a period of 1 year and re-newed annually.

## CDNs

Content Delivery Networks (CDNs) allow us to distribute static web content
across the globe to allow faster access to users.  Several good CDNs exist
today:

* CloudFront: An AWS CDN, easy to use and very affordable.
* Fast.ly: High speed CDN for the masses.
* etc.

You will require control of the DNS Zone for your sites domain.  When setting 
up the CDN your real site will become an image from which data is gathered and 
then distributed.  To route users to the nearest CDN end-point rather than 
your "real site" your DNS entry for the site is replaced with a CDN URL for your site.  

SSL will complicate matters because virtual hosting isn't supported by traditional SSL
thereby limited the number of SSL certs associated with an IP address to 1.  This means
that the CDN must have a static IP for your site at each of its end-points, which is expensive.
TLS now includes a Server Name Indication (SNI) improvements which removes this restriction,
however older clients and browsers may not support it making its adoption limited.

## Load Balancers

A load balancer accepts traffic and distributes requests to a number of "backends".  This
allows you to easily scale services  and particularly web applications.  Several different
solutions exist from the open source community, such as HAProxy, Pound, Pen, etc.  Commercial
solutions such as F5 BigIP, NetScaler, Zeus (now Riverbed) ZXTM are popular.  Several clouds 
also offer such features, such as Amazon's Elastic Load Balancer (ELB).

Load balancers will typically consist of a front-end configuration (IP and port to listen on,
rules for traffic), a list of back-end nodes (IPs and ports and rules), and then a policy
for how traffic is sent from the front-end to the back-ends.  Policy may make connections
persistant (each time a client connects its sent to the same back-end to preserve state)
or define the connection distribution pattern, such as round-robin, least-connections, fastest, etc.

Load balancers can be as simple or complex as you wish to make them.  One thing that can simplify
application deployment is to off-load HTTPS by "terminating SSL", that is, clients make
SSL connections to the load balancer front-end, where the traffic is un-encrypted and then
sent to backends.  This means that all SSL certificates and configuration can be centralized
on the load balancer!

Its important for developers to built applications with scaling, and particular load balancers,
in mind.  Are your requests truly handled in a stateless way?  Do you need to utilize session
cookies to preserve state without maintaining it in the web-server?  What are the scaling
limitations of your application so that you can capacity plan?

## Caching

There are two types of common caching scenarios: caching object store &  HTTP accelerators.

### HTTP Accelerators

HTTP Accelerators are reverse proxy servers which cache content in memory to increase
access speed.  Squid and NGINX can be used for this, but by far the most common solution
is Varnish.  When put infront of your web servers, any pages requested will be cached in
memory and thereafter served directly from memory, thereby reducing load on the web servers.

This is similar to CDN, except that GeoIP doesn't direct requests to the nearest node.  In
fact, Fastly is built with a highly customized version of Varnish.

### Caching Object Store

Accessing data from a persistant data store (aka: database) can be very time consuming and
add considerable latency to user requests.  Memcached was created as an intermediate in-memory
data store for very fast lookup for common requests (example, mapping a users email address to
their user id or password to make logins super fast).  Another very common use case is
storing session cookies.  Over time, memcache has fallen out of wide spread use and been 
replaced with Redis.

Redis is an in-memory key/value store.  "Databases" in Redis are represented by a simple integer
and can contain a variety of different data structure, but typically a simple key contains a
JSON object.  In your code, you'll query Redis, if you don't find the user, you get it from the
"real database" and then load it into the cache for next time.  The cache is inherently considered
non-persistant by design, however Redis does offer persistancy options (but note, if you use them
without a very good reason you are likely misunderstanding the purpose of Redis as a caching solution).

## SLAs

Service Level Agreements (SLAs) are legal contracts between you as a service provider and your 
customers.  They typically state some given amount of uptime will be provided or the customer
is entitled to a credit or refund of some ammount.  It is common for SLAs to state that if 
undeclared outages of longer than some period happen they will recieve a credit of X dollars
for each hour, up to the amount that they paid, within a single month.  Also, importantly,
they typically state that such a credit is only applied if the customer explicitly requests
it.  This means that, at worst, a service provider will give the customer a free month of 
service if they ask for it.

Legalities aside, SLAs are an important consideration for developers and operations team
so that they can build infrastructures which meet the requirements of the customers.

I recommend having 2 SLAs, the one you give to customers which is legally binding as described
above, and a second secret internal SLA which describes in detail the service level you
intend to provide.  This document is much more detailed including acceptable 
response times for a request, expected up time, response times, communication agreements, etc.


## Incident & Change Management

Whenever your service is adversely impacted (aka: down or preforming poorly) you have encounted
a service incident.  Monitoring should detect (predict if possible) these incidents and alert
staff so that service can be restored.  The response to such an event should be thoughly documented
and logged.  Services like Pingdom can help detect end-user impact, and services like Datadog
can corrolate and combine events from several sources (Pingdom, PagerDuty, New Relic, etc.) into
a single cohesive timeline.

Similarly, each time the infrastructure is changed it must be recorded and logged so that 
when incidents occur we can trace them back to a change event.  In addition to simply being
a good idea, this forms the foundation neccisary for achieving compliance with several 
industry audit standards to which you may at some time desire or require.

## Post Mortems & Retrospective

After any incident or change occurs, after a project completes, or even at the end of a 
given time interval, the team(s) should come together and reflect on what went well,
what didn't, and how as an organization we can improve and evolve.  This is the 
essence of "continious improvement".  These events should always be "blameless", such
that the focus is always on improving, not finger pointing and fear.   These meetings
need not be long, this is enforced particularly by mandating that any action items
determined must be assigned during the meeting, otherwise it is simply "pie in the sky"
that isn't pertinant.






