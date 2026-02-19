#!/bin/bash
  if [ -z "${1}" ]; then
    set -- /usr/bin/mongod \
      --bind_ip 0.0.0.0 \
      --port 27017 \
      --dbpath /mongodb/var \
      --unixSocketPrefix /mongodb/run
    eleven log start
  fi

  exec "$@"