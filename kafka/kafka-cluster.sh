#!/bin/bash

LOC=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
CLUSTER_HOME=$(dirname ${LOC})
. ${CLUSTER_HOME}/set-ip.sh

docker-compose -f ${LOC}/docker-compose.yml ${@}
