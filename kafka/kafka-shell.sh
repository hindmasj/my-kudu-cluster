#!/bin/bash

LOC=$(dirname $(readlink -f ${BASH_SOURCE[0]}))

docker run --rm -it --network docker_default wurstmeister/kafka bash
