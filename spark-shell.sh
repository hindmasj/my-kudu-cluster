#!/bin/bash

LOC=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
. ${LOC}/common.sh

docker run -it --rm -e KUDU_IP=${DOCKER_IP} --network ${DOCKER_NETWORK} sjh/spark
