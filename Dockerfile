# Global args
ARG BUILD_DIR=/out

#############
# Build image
FROM alpine AS builder

ARG BUILD_DIR
ARG BROKER_J_VERSION=7.1.4

WORKDIR ${BUILD_DIR}

# Download Broker-J tarball
ADD https://archive.apache.org/dist/qpid/broker-j/${BROKER_J_VERSION}/binaries/apache-qpid-broker-j-${BROKER_J_VERSION}-bin.tar.gz apache-qpid-broker-j.tar.gz
# TODO: verify PGP signature?

# Extract bin and lib dirs to ./out/
RUN mkdir ./out
RUN apk add tar
RUN tar xf apache-qpid-broker-j.tar.gz -C ${BUILD_DIR}/out --strip-components=2 qpid-broker/${BROKER_J_VERSION}/


#############
# Final image
FROM openjdk:11-jre-slim

ARG BUILD_DIR
ARG QPID_INSTALL_DIR=/usr/local/qpid
ARG QPID_WORK_DIR=/var/lib/qpid

WORKDIR ${QPID_INSTALL_DIR}

# Create qpid user and group
RUN groupadd -r qpid && useradd -r -d ${QPID_WORK_DIR} -m -g qpid qpid

# Copy qpid bin and lib dirs from build stage to /usr/local
RUN mkdir -p ${QPID_INSTALL_DIR}
COPY --from=builder ${BUILD_DIR}/out ${QPID_INSTALL_DIR}

COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

USER qpid:qpid
EXPOSE 5671 5672

CMD ["bin/qpid-server"]
