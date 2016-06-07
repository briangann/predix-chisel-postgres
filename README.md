# predix-chisel-postgres

This package provides a pre-built chisel (See  https://github.com/jpillora/chisel) binary and config that will allow external access to Postgres within predix.io.

There are 3 binaries included (Linux/OS X/Windows) which can be used as the server or client depending on arguments supplied.

The code has an additional client flag for a proxy to be specified in case you are behind a corporate firewall.

Source code will be added to this repo so you can build the code yourself.

This method can be used to expose ANY service isolated by the predix.io environment (RabbitMQ/Logstash/etc).

No security mechanisms are bypassed - everything is still over SSL, and credentials must be passed by your connecting client.

## Setup

Assuming you have no existing postgres instance in predix.io, you can create, deploy, and bind this application like this:

```
cf create-service postgres shared-nr postgres-chisel
cd app
cf push --no-start
cf bind-service predix-chisel-postgres postgres-chisel
cf env predix-chisel-postgres
  get the IP of the postgres server
  update code/Procfile
cf restage predix-chisel-postgres
```

## NOTE
On Mac OSX, you may need to "unset" an environment variable to run the client (if you have Digital Guardian installed). The binary is a golang compile, and throws an exception with DG.

Run this in the shell before launching the client:
```
export DYLD_INSERT_LIBRARIES=""
```

## Connecting the client

Use CF to get the URI of the deployed application bound to your postgres service instance. You will also need to get the IP address of the postgres server you are bound to.

```
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
