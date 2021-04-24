#!/bin/bash

LOC=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
CLUSTER_HOME=$(dirname ${LOC})
. ${CLUSTER_HOME}/common.sh

docker build -f ${LOC}/Dockerfile-zookeeper -t ${ZOOKEEPER_IMAGE} ${LOC}
docker build -f ${LOC}/Dockerfile-kafka -t ${KAFKA_IMAGE} ${LOC}

#docker scan ${ZOOKEEPER_IMAGE}
#docker scan ${KAFKA_IMAGE}