FROM centos:7 AS builder

ARG BROKER_J_VERSION=7.1.4
ARG WORKDIR=/work

WORKDIR ${WORKDIR}
RUN mkdir ./out
RUN curl -o ./apache-qpid-broker-j.tar.gz https://archive.apache.org/dist/qpid/broker-j/${BROKER_J_VERSION}/binaries/apache-qpid-broker-j-${BROKER_J_VERSION}-bin.tar.gz
RUN tar xf ./apache-qpid-broker-j.tar.gz -C ${WORKDIR}/out --strip-components=2 qpid-broker/${BROKER_J_VERSION}/bin
RUN tar xf ./apache-qpid-broker-j.tar.gz -C ${WORKDIR}/out --strip-components=2 qpid-broker/${BROKER_J_VERSION}/lib

FROM openjdk:11-jre-slim
ARG WORKDIR=/work
COPY --from=builder ${WORKDIR}/out /usr/local/
