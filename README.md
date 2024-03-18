# Trying and failing to setup MongoDB locally

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

If you modify the Docker Compose setup, make sure to delete the volume that holds the MongoDB data. Otherwise changes might not be picked up.

