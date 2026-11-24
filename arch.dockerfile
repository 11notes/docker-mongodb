# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_VERSION=0 \
      APP_GO_VERSION=0

# :: FOREIGN IMAGES
  FROM 11notes/util AS util
  FROM 11notes/distroless AS distroless
  FROM 11notes/distroless:tini-pm AS distroless-tini-pm
  FROM 11notes/distroless:ds AS distroless-ds


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: BACKUP
  FROM 11notes/go:${APP_GO_VERSION} AS backup
  COPY ./build /

  RUN set -ex; \
    cd /go/backup; \
    eleven go build /backup main.go;

  RUN set -ex; \
    eleven distroless /backup;


# :: HEALTHCHECK
  FROM 11notes/go:${APP_GO_VERSION} AS healthcheck
  COPY ./build /

  RUN set -ex; \
    cd /go/healthcheck; \
    eleven go build /healthcheck main.go;

  RUN set -ex; \
    eleven distroless /healthcheck;


# :: MONGODB
  FROM debian:bookworm-slim AS build
  COPY --from=distroless-ds / /
  ARG TARGETARCH \
      APP_UID \
      APP_GID \
      APP_VERSION \
      BUILD_ROOT=/distroless \
      BUILD_BIN=/opt/mongodb/bin

  RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      libcurl4 \
      libssl3 \
      liblzma5 \
      binutils \
      xz-utils;

  RUN set -ex; \
    case "${TARGETARCH}" in \
      amd64) MONGO_ARCH="x86_64-ubuntu2204";; \
      arm64) MONGO_ARCH="aarch64-ubuntu2204";; \
    esac; \
    mkdir -p /tmp/mongo; \
    curl -fsSL "https://fastdl.mongodb.org/linux/mongodb-linux-${MONGO_ARCH}-${APP_VERSION}.tgz" \
      | tar -xz --strip-components=1 -C /tmp/mongo; \
    mkdir -p ${BUILD_ROOT}${BUILD_BIN}; \
    cp /tmp/mongo/bin/mongod ${BUILD_ROOT}${BUILD_BIN}/mongod;

  RUN set -ex; \
    ds ${BUILD_ROOT}${BUILD_BIN}/mongod; \
    ds --bye;

  RUN set -ex; \
    ldd ${BUILD_ROOT}${BUILD_BIN}/mongod \
      | grep -oE '/[^ ]+' \
      | sort -u \
      | while read -r LIB; do \
          cp --parents -L "${LIB}" ${BUILD_ROOT}; \
        done;

  RUN set -ex; \
    # check built version against desired version
    ${BUILD_ROOT}${BUILD_BIN}/mongod --version | grep -q "${APP_VERSION}"


# :: FILE SYSTEM
  FROM alpine AS file-system
  COPY ./rootfs/ /distroless
  ARG APP_ROOT

  RUN set -ex; \
    mkdir -p /distroless${APP_ROOT}/etc; \
    mkdir -p /distroless${APP_ROOT}/var; \
    mkdir -p /distroless${APP_ROOT}/backup;

  RUN set -ex; \
    printf '%s\n' \
      'storage:' \
      '  dbPath: /mongodb/var' \
      'net:' \
      '  port: 27017' \
      '  bindIp: 0.0.0.0' \
      '  unixDomainSocket:' \
      '    enabled: false' \
      'processManagement:' \
      '  fork: false' \
      > /distroless${APP_ROOT}/etc/mongod.conf;


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
# :: HEADER
  FROM scratch

  # :: default arguments
    ARG TARGETPLATFORM \
        TARGETOS \
        TARGETARCH \
        TARGETVARIANT \
        APP_IMAGE \
        APP_NAME \
        APP_VERSION \
        APP_ROOT \
        APP_UID \
        APP_GID \
        APP_NO_CACHE

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
        APP_NAME=${APP_NAME} \
        APP_VERSION=${APP_VERSION} \
        APP_ROOT=${APP_ROOT}

  # :: multi-stage
    COPY --from=distroless / /
    COPY --from=build /distroless/ /
    COPY --from=backup /distroless/ /
    COPY --from=healthcheck /distroless/ /
    COPY --from=file-system --chown=${APP_UID}:${APP_GID} /distroless/ /
    COPY --from=distroless-tini-pm / /

# :: STORAGE
  VOLUME ["${APP_ROOT}/var"]

# :: HEALTH
  HEALTHCHECK --interval=5s --timeout=2s --start-interval=5s \
    CMD ["/usr/local/bin/healthcheck"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/tini-pm"]