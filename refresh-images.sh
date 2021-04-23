#!/bin/bash

LOC=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
. ${LOC}/common.sh

# The cluster relies on a number of images that can be pulled and refreshed at intervals

# Base Images
BASE_IMAGES="${KUDU_IMAGE} ${IMPALA_IMAGE} ${SPARK_BASE_IMAGE} ${ZOOKEEPER_BASE_IMAGE} ${KAFKA_BASE_IMAGE}"
for image in ${BASE_IMAGES}
do
    docker pull ${image}
done

# Built Images
docker build -f Dockerfile-spark -t ${SPARK_IMAGE} ${LOC}
${LOC}/kafka/build-images.sh

docker image prune -f

# Scan final images
FINAL_IMAGES="${KUDU_IMAGE} ${IMPALA_IMAGE} ${SPARK_IMAGE} ${ZOOKEEPER_IMAGE} ${KAFKA_IMAGE}"
for image in ${FINAL_IMAGES}
do
    docker scan ${image}
done

# Push locally built images
docker push ${SPARK_IMAGE}
