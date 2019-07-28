# Global args
ARG BUILD_DIR=/out

#############
# Build image
FROM alpine AS builder

ARG BUILD_DIR
ARG BROKER_J_VERSION=7.1.4

WORKDIR ${BUILD_DIR}

# Download Broker-J tarball
ADD https://archive.apache.org/dist/qpid/broker-j/${BROKER_J_VERSION}/binaries/apache-qpid-broker-j-${BROKER_J_VERSION}-bin.tar.gz \
    ${BUILD_DIR}/apache-qpid-broker-j.tar.gz
# TODO: verify PGP signature?

# Extract qpid binaries to ./out/
RUN mkdir ${BUILD_DIR}/out
RUN apk add tar
RUN tar xf ${BUILD_DIR}/apache-qpid-broker-j.tar.gz -C ${BUILD_DIR}/out --strip-components=2 qpid-broker/${BROKER_J_VERSION}/


#############
# Final image
FROM openjdk:11-jre-slim

ARG BUILD_DIR
ARG QPID_INSTALL_DIR=/usr/local
ARG QPID_WORK_DIR=/var/lib/qpid

# Set env vars expected by qpid
ENV QPID_HOME=${QPID_INSTALL_DIR}
ENV QPID_WORK=${QPID_WORK_DIR}

# Create qpid user and group
RUN groupadd --system --gid 1000 qpid && \
    useradd  --system --no-log-init \
             --create-home --home-dir ${QPID_WORK_DIR} \
             --uid 1000 --gid qpid qpid
WORKDIR ${QPID_WORK_DIR}

# Copy qpid binaries from build stage to /usr/local
RUN mkdir -p ${QPID_INSTALL_DIR}
COPY --from=builder ${BUILD_DIR}/out ${QPID_INSTALL_DIR}

# Copy initial-config.json
COPY initial-config.json ${QPID_HOME}/etc/

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

USER qpid:qpid
EXPOSE 5672 8080
VOLUME ${QPID_WORK_DIR}

CMD ["qpid-server", "--initial-config-path", "${QPID_HOME}/etc/initial-config.json"]
