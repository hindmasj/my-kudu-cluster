#!/bin/bash

LOC=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
KUDU=$(dirname ${LOC})/kudu
. ${LOC}/set-ip.sh

docker-compose -f ${KUDU}/docker/quickstart.yml ${@}
