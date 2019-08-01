# Global arg, see hooks/build for default value
ARG BROKER_J_VERSION

#############
# Build image
FROM alpine AS builder

ARG BROKER_J_VERSION

WORKDIR /workspace

# Download Broker-J tarball and extract binaries to ./out/
RUN mkdir out
# TODO: verify PGP signature?
ADD https://archive.apache.org/dist/qpid/broker-j/${BROKER_J_VERSION}/binaries/apache-qpid-broker-j-${BROKER_J_VERSION}-bin.tar.gz \
    apache-qpid-broker-j.tar.gz
RUN apk add tar
RUN tar xf apache-qpid-broker-j.tar.gz -C out --strip-components=2 qpid-broker/${BROKER_J_VERSION}/


#############
# Final image
FROM openjdk:11-jre-slim

ARG BROKER_J_VERSION
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

# Set env vars expected by qpid
ENV QPID_HOME=/usr/local
ENV QPID_WORK=/var/lib/qpid
ENV QPID_RUN_LOG=2

# Build-time metadata as defined at http://label-schema.org
LABEL org.label-schema.build-date=${BUILD_DATE} \
      org.label-schema.name="qpid-broker-j" \
      org.label-schema.description="Docker image for Apache Qpid Broker-J" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.vcs-url="https://www.github.com/chrisob/qpid-broker-j-docker" \
      org.label-schema.version=${VERSION} \
      org.label-schema.schema-version="1.0"

# Create qpid user and group
RUN groupadd --system --gid 1000 qpid && \
    useradd  --system --no-log-init \
             --create-home --home-dir ${QPID_WORK} \
             --uid 1000 --gid qpid qpid
WORKDIR ${QPID_WORK}

# Copy qpid binaries from build stage to /usr/local
RUN mkdir -p ${QPID_HOME}
COPY --from=builder /workspace/out ${QPID_HOME}

# Copy initial-config.json
COPY initial-config.json ${QPID_HOME}/etc/

USER qpid:qpid
EXPOSE 5672 8080
VOLUME ${QPID_WORK}

CMD ["qpid-server", "--initial-config-path", "${QPID_HOME}/etc/initial-config.json"]
