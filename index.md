% CCNQ(4)
% Stéphane Alnet
% RMLL, July 2015

----------

CCNQ was <strong>born in 2006</strong>.

That's 9 years ago.

----------

What happened during these 9 years?

# <span class="try">Let's go</span> Historical


## <span class="tiny">v0.x (2006)</span> ssh push
### (think ansible)

* System and customer configuration in a single document.
* Only OK when you're doing a couple changes a day.
* Code was lost in the Carribeans.

## <span class="tiny">v1.5 (2007)</span> Perl (sync)
### CouchDB?

* Barely better.
* Code also thankfully lost.

## <span class="tiny">v2.0 (2009)</span> Perl async, CouchDB

* CouchDB on each call-processing server
* Perl async for realtime change management
* Task management via CouchDB
* Everything: provisioning, rating, UI, ...
* Perl <em>packages</em>

----------------

Doing async in Perl is <strong>hard</strong>.

<div class="notes">
- No unified model for callbacks
- Incompatibilities between modules
- Never was able to get a CouchDB/AMQP/FileSystem synchronization to work properly.
</div>

## <span class="tiny">v3 (2010)</span> Node.js, CouchDB, RabbitMQ

* Focus on deployable call-processing
* Node.js for async
* Debian packages
* AMQP for M2M
* Host configurations in CouchDB
* CouchDB-based DNS

<div class="notes">
Host configuration changes dynamically update.
</div>

----------

Debian packages are <strong>hard</strong>.

AMQP is verbose.
<span class="small">(Also: 1ko limit per message?)</span>

## <span class="tiny">v4 (2014)</span> <span class="small">Node.js, CouchDB,</span> Docker.io,  Socket.IO

* Docker.io: one app, one container.
* Apps built out of <span class="tiny">tiny</span> components.
* <code>package.json</code> &amp; <code>git</code> for (<strong>strong</strong>) dependency management.
* <code>Socket.io</code> for M2M &amp; UI
* Host configurations in git(lab)

<div class="notes">
Host configurations in git(lab) really is a workaround.
Ideally should move back to a database-centric approach to host provisioning.
Lots of code to migrate from CCNQ3, still iterating.
</div>

# <span class="- try">Let's talk</span> About Code

## Guiding Principles

* Same modules on the server and the client:
  PouchDB, Socket.io-client, superagent, bluebird (Promises)
* APIs: REST/JSON and Socket.IO only
<div class="notes">No HTML generated on servers, use templating on the client.</div>
* Prefer `changes` over directives

## Promises

<q>This isn't 2011 anymore.</q>

```coffeescript
serialize cfg, 'config' 
```
<div class="notes">
Configure using `config` middlewares.
</div>

```coffeescript
.then ->
  unless cfg.server_only is true
    fs.writeFileAsync process.env.FSCONF, xml, 'utf-8'
```
<div class="notes">
Write FreeSwitch XML configuration (if needed)
</div>

```coffeescript
.then ->
  supervisor.startProcessAsync 'server'
```
<div class="notes">
Start the call-handler service
</div>

```coffeescript
.then ->
  unless cfg.server_only is true
    supervisor.startProcessAsync 'freeswitch'
```
<div class="notes">
Start FreeSwitch (if needed)
</div>

```coffeescript
.then ->
  debug 'Done'
```
<div class="notes">
Source: thinkable-ducks/config
</div>

## Fluency

```coffeescript
SuperAgent
.get "#{@cfg.auth_base ? @cfg.proxy_base}/_session"
.accept 'json'
.auth user.name, user.pass
```
<div class="fragment">
```coffeescript
.then ({body}) =>
  @session.couchdb_username = body.userCtx.name
  @session.couchdb_roles = body.userCtx.roles
  @session.couchdb_token = hex_hmac_sha1 @cfg.couchdb_secret, @session.couchdb_username
```
</div>
<div class="notes">
Source: spicy-action/couchdb-auth
Uses package `superagent-as-promised`
Illustrates combining fluency with Promises.
</div>

## <span class="try">Domain-Specifc Languages</span>DSL

```coffeescript
require('zappajs') cfg.web, ->

  @get '/', ->
    @json
      ok: true
      name: pkg.name
      version: pkg.version
```

<div class="fragment">
```coffeescript
  db = new PouchDB cfg.db

  @get '/forwarding/:number', ->
    db.get @param.number
    .then (doc) =>
      @json forwarding: doc.forwarding
```
</div>
<div class="notes">
    cfg = require process.env.CONFIG ? './local/config.json'
    pkg = require './package.json'
    PouchDB = require 'pouchdb'
    db = new PouchDB cfg.db
</div>

-----------

```coffeescript
require('zappajs') cfg.web, ->

  @on trace: ->
    if @session.admin
      @broadcast_to 'trace-servers', 'trace', @data
```

```coffeescript
client = require('socket.io-client') process.env.SOCKET

client.on 'trace', (doc) ->
  client.emit 'trace_started', host:hostname, in_reply_to:doc
  Promise.resolve()
  .then ->
    trace doc
  .then ->
    client.emit 'trace_completed', host:hostname, in_reply_to:doc
  .catch (error) ->
    client.emit 'trace_error', 
      host: hostname
      in_reply_to: doc
      error: error
```
<div class="notes">
Source: project `nifty-ground`.
</div>

## <span class="try">Domain-Specifc Languages</span>Voicemail

<div class="notes">
```coffeescript
class User
  constructor: (@ctx,@id,@database,@db_uri) ->
    @db = new PouchDB @db_uri
```
</div>

```coffeescript
class User

  main_menu: ->
    @call.get_choice "phrase:voicemail_main_menu"
    .then (choice) =>
      switch choice

        when "1"
          @retrieve_new_messages()
          .then (rows) =>
            @navigate_messages rows, 0
          .then =>
            @main_menu()

        when "3"
          @config_menu()
```

<div class="notes">
```
@include = (ctx) ->
  ctx.get_choice = (file) =>
    ctx.action 'play_and_get_digits', "1 1 1 1000 # #{file} silence_stream://250 choice"
    .then ({body}) ->
      body.variable_choice
```
</div>
<div class="notes">
Souce: project `well-groomed-feast`.
</div>

# <span class="try">Let's talk about</span>Fun

## `esl` module

- provides *client* access to FreeSwitch events socket
<div class="notes">e.g. to build a dialer</div>

- provides *server* access to FreeSwitch events socket
<div class="notes">inbound call handling</div>

Success Story

- used in production and to build new services

-----------

Testability

- `esl` has both unitary tests and live tests
- live tests involve starting and stopping FreeSwitch: much easier with Docker.io!

## Middleware <span class="try">`useful-wind`</span>

* Take the <em>middleware</em> concept from Connect / Express / Zappa
* Apply it to voice calls
* Build call-processing applications by combining (npm) modules

## Middleware Power <span class="try">`thinkable-ducks`</span>

- process calls (ESL)
- access CouchDB (PouchDB)
- receive and send events (Socket.IO-client)
- serve APIs (ZappaJS)

------------

Examples:

- `tough-rate` LCR engine used in production at K-net
- `well-groomed-feast` voicemail engine

## Distributed Sniffer <span class="try">`nifty-ground`</span>

-------------

*Browser*

- Request generated by JS on the browser
- Sent over Socket.io to dispatcher.

----------

*Server*

- Process on each server waits for request from dispatcher
- Send notification → browser builds list of expected responses
- Queries captures files
- Send notification (with data)
- Store PCAP file (last 500 packets) in CouchDB

# More Fun

## PouchDB

Browser:

```coffeescript
db = new PouchDB 'users'

db.put _id:'shimaore', name:'Stéphane Alnet'
.then ->
  db.get 'shimaore'
.then (doc) ->
  assert doc.name is 'Stéphane Alnet'
.catch (error) ->
  cuddly.csr "Could not retrieve shimaore: #{error}"
```
<div class="notes">
All accesses are local to the browser. Database is persisted.
</div>

-----------

Browser: Access CouchDB

```coffeescript
db = new PouchDB 'https://couchdb.example.net:6984/users'
```

----------

Sync Browser ←→ CouchDB

```coffeescript
PouchDB.sync 'users', 'https://couchdb.example.net:6984/users'
```

<div class="notes">
Two-way replication. Also exist as one-way replication with `replicate`.
Offline-first made easy. Also check out Hoodie.hq!
</div>

-----------

Server: Use local database

```coffeescript
db = new PouchDB 'users'
```

## Docker.io

- In production we use `--network=host`
<div class="notes">
Although it would help greatly document things if we were using the Docker connection thingies. But we do a lot of UDP and kernel-level stuff for speed.
</div>
- Lessons learned: need to consider containers as read-only images
<div class="notes">
Otherwise they grow larger and larger in production due to AUFS.
Use mountpoint for logs, live data.
</div>
- It's hard to use independent UIDs inside containers.
<div class="notes">
When mounting logs etc the UIDs are kept identical, often resulting in access issues.
</div>
- `docker-ccnq` module (internal) to ensure proper start of containers.
<div class="notes">
Essentially git pull at install + `for dir in ~docker/start/[0-9]*; do cd $dir && ./init start; done`
</div>
- Large amount of disk vs compression.
<div class="notes">
Docker.io uses large amounts of disk because the intermediary (build) steps of a Dockerfile are part of the final image.
Compression (=keep only data that is still present) is a hotly debated topic.
</div>


## <span class="try">JSON Swiss Army Knife</span>JQ

```sh
rest -G \
  -d startkey='\"rule:16171\"' \
  -d endkey='\"rule:1617999\"' \
  https://couchdb.example.net/ruleset/_all_docs | \

jq '{docs: (.rows | map({ _id: .id, _rev: .value.rev, _deleted:true })) }'  \

rest -X POST --data-binary @- \
  https://couchdb.example.net/ruleset/_bulk_docs
```
<div class="notes">
The command-line is alive and well!

`rest` is:

    curl -n \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      "$@"
</div>


## And more fun

* Project Metadata - `package.json`
<div class="notes">
applies to npm, but I also use it in the Makefile that builds Docker images to figure out the version (`tag`) to apply to the docker build
</div>
* Semantic Versioning - http://semver.org/
* Dependency locking
<div class="notes">
applies to `npm` and others, e.g. tshark in nifty-ground's Dockerfile
</div>
* Dependencies management: `npm`, `Dockerfile`; Gemnasium

## Thank you | Merci

* **CCNQ** http://ccnq.shimaore.net/
* **Code** https://github.com/shimaore/
* **Contact** http://stephane.shimaore.net/
