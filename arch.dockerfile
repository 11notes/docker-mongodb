# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_VERSION=0

# :: FOREIGN IMAGES
  FROM 11notes/util AS util
  FROM 11notes/distroless:tini-pm AS distroless-tini-pm
  FROM 11notes/distroless:ds AS distroless-ds


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: BACKUP
  FROM 11notes/go:1.25 AS backup
  COPY ./build /

  RUN set -ex; \
    cd /go/backup; \
    eleven go build /backup main.go;

  RUN set -ex; \
    eleven distroless /backup;


# :: HEALTHCHECK
  FROM 11notes/go:1.25 AS healthcheck
  COPY ./build /

  RUN set -ex; \
    cd /go/healthcheck; \
    eleven go build /healthcheck main.go;

  RUN set -ex; \
    eleven distroless /healthcheck;


# :: MONGODB
  FROM 11notes/debian:12 AS build
  COPY --from=util / /
  COPY --from=distroless-ds / /
  ARG TARGETARCH
  USER root
  ADD http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.1_1.1.1w-0+deb11u4_${TARGETARCH}.deb /tmp/libssl1.1.deb
  ADD https://repo.mongodb.org/apt/ubuntu/dists/focal/mongodb-org/4.4/multiverse/binary-${TARGETARCH}/mongodb-org-server_4.4.30_${TARGETARCH}.deb /tmp/mongodb-org-server.deb
  ADD https://repo.mongodb.org/apt/ubuntu/dists/focal/mongodb-org/4.4/multiverse/binary-${TARGETARCH}/mongodb-database-tools_100.9.5~90481484_${TARGETARCH}.deb /tmp/mongodb-database-tools.deb
  ENV DEBIAN_FRONTEND=noninteractive

  RUN set -ex; \
    eleven apt install \
      libcurl4;

  RUN set -ex; \
    dpkg -i /tmp/libssl1.1.deb; \
    dpkg -i /tmp/mongodb-org-server.deb || echo "true"; \
    dpkg -i /tmp/mongodb-database-tools.deb;

  RUN set -ex; \
    find /bin /sbin /usr/bin /usr/sbin -type f -executable \
      -name "mongo*" \
    -exec /usr/local/bin/ds {} ';'; \
    /usr/local/bin/ds --bye;

  RUN set -ex; \
    eleven cleanup;

# :: FILE SYSTEM
  FROM alpine AS file-system
  COPY ./rootfs/ /distroless
  ARG APP_ROOT

  RUN set -ex; \
    mkdir -p /distroless${APP_ROOT}/var; \
    mkdir -p /distroless${APP_ROOT}/run; \
    mkdir -p /distroless${APP_ROOT}/backup; \
    chmod +x -R /distroless/usr/local/bin;


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

  # :: app specific environment
    ENV DEBIAN_FRONTEND=noninteractive

  # :: multi-stage
    COPY --from=build / /
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