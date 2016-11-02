# predix-chisel-postgres

This Cloud Foundry application allows you to connect to "internal" only services, specifically the Postgres service, but can be extended to others as well.

Pre-built chisel (See  https://github.com/jpillora/chisel) binaries are included.

There are 3 binaries included (Linux/OS X/Windows) which can be used as the server or client depending on arguments supplied.

The codebase has an additional client flag for a proxy to be specified in case you are behind a corporate firewall.

This method can be used to expose ANY service isolated by the predix.io environment (RabbitMQ/Logstash/etc).

No security mechanisms are bypassed - everything is still over SSL, and credentials must be passed by your connecting client.

Source code for the client that includes the proxy code can be built by cloning https://github.com/chromicant/chisel/tree/proxy
If you are not behind a proxy, you can use the binary releases from the main chisel repo.

## Setup

Assuming you have no existing postgres instance in predix.io, you can create, deploy, and bind this application like this:

```
cf create-service postgres shared-nr postgres-chisel
cd app
cf push --no-start
cf bind-service predix-chisel-postgres postgres-chisel
cf restage predix-chisel-postgres
```

## NOTE
On Mac OSX, you may need to "unset" an environment variable to run the client (if you have Digital Guardian installed). The binary is a golang compile, and throws an exception with DG.

Run this in the shell before launching the client:
```
export DYLD_INSERT_LIBRARIES=""
```

## Connecting the client (the easy way)

Inside the bin folder, there is a script for connecting to your chisel server, invoking psql/mysql automatically. It will also detect if you have "https_proxy" set
and pass the appropriate argument.

On MacOS, you can use homebrew to install dependencies "jq" and "psqlodbc"

```
brew install psqlodbc
brew install jq
```

Highly recommend using "cf-traveling-admin" from https://github.com/cloudfoundry-community/traveling-cf-admin

```
./bin/client_connect.sh APP_NAME
```

Here's an example:

```
$ ./bin/client_connect.sh predix-chisel-postgres
2016/11/01 21:33:33 client: Connecting to wss://predix-chisel-postgres-nonsecretive-bioastronautics.run.aws-usw02-pr.ice.predix.io:443
2016/11/01 21:33:33 client: 10.72.6.121:5432#1: Enabled
2016/11/01 21:33:34 client: Fingerprint 6f:8d:b3:a2:7a:92:e5:03:e7:ec:e7:cb:17:b5:de:f2
2016/11/01 21:33:34 client: Sending configurating
2016/11/01 21:33:34 client: Connected (Latency 175.246893ms)
===============================
APP_GUID: eda21d05-46a9-4d0a-8fff-40145d57ceca
APP_DOMAIN: https://predix-chisel-postgres-nonsecretive-bioastronautics.run.aws-usw02-pr.ice.predix.io

postgres CREDENTIALS

SERVICE NAME: postgres-bg
SERVICE DATABASE: d9e523c2fa5614b979a11b1944b3b3202
SERVICE USERNAME: MYUSERNAME
SERVICE PASSWORD: MYPASSWORD

LOCAL PORT: 15524
REMOTE HOST: 10.72.6.121
REMOTE PORT: 5432

===============================
2016/11/01 21:33:36 client: 10.72.6.121:5432#1: conn#1: Open
psql (9.5.4, server 9.4.5)
Type "help" for help.

d9e523c2fa5614b979a11b1944b3b3202=>
```
## Connecting the client manually

Use CF to get the URI of the deployed application bound to your postgres service instance. You will also need to get the IP address of the postgres server you are bound to.

```
cf env predix-chisel-postgres

{
 "VCAP_SERVICES": {
  "postgres": [
   {
    "credentials": {
     "database": "mydatabaseinstance",
     "host": "10.72.6.121",
     "password": "mysecretpassword",
     "port": "5432",
     "username": "myusername"
    },
   },
```

Get the URI to your application from the VCAP_APPLICATION section:
```
{
 "VCAP_APPLICATION": {
  "application_uris": [
   "predix-chisel-postgres-nonsecretive-bioastronautics.run.aws-usw02-pr.ice.predix.io"
  ],
 }
}
```

```
cf env predix-chisel-postgres
```
Run the client on your local machine, here are examples:

NO PROXY
```

Start client on OS X, locally bound to port 4000:

./chisel_darwin_amd64 client -v --keepalive 3s https://predix-chisel-postgres-nonsecretive-bioastronautics.run.aws-usw02-pr.ice.predix.io 4000:10.72.6.133:5432

Start client on Linux locally bound to port 4000:

./chisel_linux_amd64 client -v --keepalive 3s https://predix-chisel-postgres-nonsecretive-bioastronautics.run.aws-usw02-pr.ice.predix.io 5000:10.72.6.133:5432
```

WITH PROXY
```
./chisel_darwin_amd64 client -v --proxy https://mycorporateproxy.foo.com:80 --keepalive 3s https://predix-chisel-postgres-nonsecretive-bioastronautics.run.aws-usw02-pr.ice.predix.io 4000:10.72.6.139:5432
```

## Connect!

Use any postgres client (SQuirreL, Postico, etc).

You will connect to your local machine, which will forward to the predix application.

Example for Postico:

* host: localhost
* port: 4000
* user: username from VCAP_SERVICES
* password: password from VCAP_SERVICES
* database: database name from VCAP_SERVICES
