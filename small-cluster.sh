#!/bin/bash

LOC=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
KUDU=$(dirname ${LOC})/kudu

docker-compose -f ${KUDU}/docker/docker-compose.yml ${@}
