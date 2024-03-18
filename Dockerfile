ARG MONGO_VERSION

FROM mongo:${MONGO_VERSION}

COPY --chmod=600 --chown=mongodb:mongodb keyfile /data/keyfile

# we take over the default & start mongo in replica set mode in a background task
ENTRYPOINT docker-entrypoint.sh --port $MONGO_REPLICA_PORT --replSet rs0 --bind_ip 0.0.0.0 --keyFile '/data/keyfile' & MONGOD_PID=$!; \
  # we prepare the replica set with a single node and prepare the root user config
  INIT_REPL_CMD="try {rs.status()} catch {rs.initiate({ _id: 'rs0', members: [{_id: 0, host: '$MONGO_REPLICA_HOST:$MONGO_REPLICA_PORT'}]})}"; \
  # we wait for the replica set to be ready and then submit the command just above
  until ($MONGO_COMMAND -u $MONGO_INITDB_ROOT_USERNAME -p $MONGO_INITDB_ROOT_PASSWORD --port $MONGO_REPLICA_PORT --eval "$INIT_REPL_CMD"); do sleep 1; done; \
  # we are done but we keep the container by waiting on signals from the mongo task
  echo "REPLICA SET ONLINE"; wait $MONGOD_PID;
