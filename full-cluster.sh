#!/bin/bash

LOC=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
COMPOSE=${LOC}/kudu-cluster.yml

DOCKER_IP=$(ip addr | grep eth0 | tail -1 | \
    awk '{split($2,a,"/");print a[1]}')
export DOCKER_IP

KUDU_IMAGE=apache/kudu:latest
KUDU_MASTERS=kudu-master-0:7051,kudu-master-1:7151,kudu-master-2:7251
MASTER_CONTAINER=kudu-master
export KUDU_IMAGE KUDU_MASTERS MASTER_CONTAINER

IMPALA_CONTAINER=kudu-impala
IMPALA_IMAGE=apache/kudu:impala-latest
IMPALA_PORT_MAP="-p 21000:21000 -p 21050:21050 -p 25000:25000 -p 25010:25010 -p 25020:25020"
export IMPALA_CONTAINER IMPALA_IMAGE IMPALA_PORT_MAP

docker-compose -f ${COMPOSE} ${@}
