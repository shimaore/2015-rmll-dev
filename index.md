% CCNQ(4)
% Stéphane Alnet
% RMLL, July 2015

----------

CCNQ was <strong>born in 2006</strong>.
That's 9 years ago.

----------

What happened during these 9 years?

# <span class="try">Let's go</span> Historical


## v0.x (2006): ssh push (think ansible)

* System and customer configuration in a single document.
* Only ok when you're doing a couple changes a day.
* Code was lost in the Carribeans.

## v1.5 (2007): Perl (sync), CouchDB?

* Barely better
* Code also thankfully lost.

## v2.0 (2009): Perl async, CouchDB

* CouchDB on each call-processing server
* Perl async for realtime change management
* Task management via CouchDB
* Everything: provisioning, rating, UI, ...
* Perl <em>packages</em>

----------------

Doing async in Perl is <strong>hard</strong>.

## v3 (2010): Node.js, CouchDB, RabbitMQ

* Focus on deployable call-processing
* Node.js for async
* Debian packages
* AMQP for M2M
* Host configurations in CouchDB

----------

Debian packages are <strong>hard</strong>.
AMQP is verbose.

## v4 (2014): Docker.io, Node.js, CouchDB, Socket.IO

* Docker.io: one app, one container
* Apps built out of <span class="tiny">tiny</span> components.
* <code>npm</code> for (<strong>strong</strong>) dependency management
* <code>Socket.io</code> for M2M &amp; UI
* Host configurations in git(lab)
