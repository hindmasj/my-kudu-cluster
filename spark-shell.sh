#!/bin/bash

LOC=$(dirname $(readlink -f ${BASH_SOURCE[0]}))

. ${LOC}/set-ip.sh

docker run -it --rm -e KUDU_IP=${KUDU_QUICKSTART_IP} sjh/spark
