# Trying and failing to setup MongoDB locally

**The solution is to use the `extra_hosts` option in the `docker-compose.yml` file.** See the [`extra_hosts`](#extra_hosts) section for more details.

This repository demonstrates the difficulty with setting up MongoDB locally using Docker Compose. The goal is to have a MongoDB replica set running as a Docker Compose service, and being able to connect to it from the host and from another Docker Compose service.

The setup is modeled after [this link](https://github.com/prisma/prisma/discussions/22442%C2%AC). I also read [this issue](https://github.com/prisma/docs/issues/3040).

The exact steps that should work but don't are:

```shell
$ docker compose up mongo --build
$ docker compose up app --build
$ ./check_status
```

The first command sets up the database, the second and third just run the `rs.status()` command. Both should return successfully. Right now, the second command fails with this error:

```text
$ ./check_status
Current Mongosh Log ID: 65f83906c5927e356113556b
Connecting to:          mongodb://<credentials>@127.0.0.1:27020/foo?replicaSet=rs0&serverSelectionTimeoutMS=2000&authSource=admin&appName=mongosh+2.1.5
MongoNetworkError: getaddrinfo ENOTFOUND mongo
```

If you modify the Docker Compose setup, make sure to delete the volume that holds the MongoDB data with `docker compose down --volumes`. Otherwise changes might not be picked up.

## Possible solutions

### Modify the `hosts` file

The solution should be self-contained, and not require any manual setup on the host machine. This is why I'm not considering this solution.

### `network_mode: host`

Doesn't work on MacOS. Applying the following Git diff won't work, likely due to [this issue](https://github.com/docker/for-mac/issues/1031).

```diff
    diff --git a/docker-compose.yml b/docker-compose.yml
    index 9c268c0..7d5c8d6 100644
    --- a/docker-compose.yml
    +++ b/docker-compose.yml
    @@ -13,6 +13,7 @@ services:
         ]
     
       mongo:
    +    network_mode: "host"
         build:
           context: .
           args:
    @@ -20,11 +21,9 @@ services:
         environment:
           MONGO_INITDB_ROOT_USERNAME: root
           MONGO_INITDB_ROOT_PASSWORD: root
    -      MONGO_REPLICA_HOST: mongo
    +      MONGO_REPLICA_HOST: localhost
           MONGO_REPLICA_PORT: 27020
           MONGO_COMMAND: "mongosh"
    -    ports:
    -      - "27020:27020"
         restart: unless-stopped
         healthcheck:
           test: [ "CMD", "mongosh", "admin", "--port", "$$MONGO_REPLICA_PORT", "--eval", "db.adminCommand('ping').ok" ]
```

### `extra_hosts`

**This seems to be the correct solution and it was tested on MacOS and Linux.** Run the MongoDB service in the Docker Compose network, but expose its port so we can connect to it from the host. Next, make other Docker Compose services connect to the host by mapping `localhost` to the `host-gateway`. You can't just use `host.docker.internal`, because the replica set is listening for connections on `localhost`. See the Git diff:

```diff
diff --git a/docker-compose.yml b/docker-compose.yml
index 9c268c0..1915d80 100644
--- a/docker-compose.yml
+++ b/docker-compose.yml
@@ -4,8 +4,10 @@ services:
   app:
     image: mongo:5
     entrypoint: mongosh 
+    extra_hosts:
+      - "localhost:host-gateway"
     command: [ 
-      "mongodb://root:root@mongo:27020/foo?replicaSet=rs0",
+      "mongodb://root:root@localhost:27020/foo?replicaSet=rs0",
       "--authenticationDatabase",
       "admin",
       "--eval",
@@ -20,7 +22,7 @@ services:
     environment:
       MONGO_INITDB_ROOT_USERNAME: root
       MONGO_INITDB_ROOT_PASSWORD: root
-      MONGO_REPLICA_HOST: mongo
+      MONGO_REPLICA_HOST: localhost
       MONGO_REPLICA_PORT: 27020
       MONGO_COMMAND: "mongosh"
     ports:
```
