#!/bin/bash

LOC=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
. ${LOC}/common.sh

docker-compose -f ${COMPOSE} ${@}
