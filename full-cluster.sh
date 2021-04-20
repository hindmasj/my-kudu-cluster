#!/bin/bash

LOC=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
. ${LOC}/common.sh

echo "Cluster address is ${DOCKER_IP}"

docker-compose -f ${COMPOSE} ${@}
