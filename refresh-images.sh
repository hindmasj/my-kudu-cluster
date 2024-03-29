#!/bin/bash

LOC=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
. ${LOC}/common.sh

# The cluster relies on a number of images that can be pulled and refreshed at intervals
USED_IMAGES="${KUDU_IMAGE} ${IMPALA_IMAGE}"
BUILT_IMAGES="${SPARK_IMAGE} ${ZOOKEEPER_IMAGE} ${KAFKA_IMAGE}"

BASE_IMAGES="${USED_IMAGES} ${SPARK_BASE_IMAGE} ${ZOOKEEPER_BASE_IMAGE} ${KAFKA_BASE_IMAGE}"
FINAL_IMAGES="${USED_IMAGES} ${BUILT_IMAGES}"

# Base Images
for image in ${BASE_IMAGES}
do
    docker pull ${image}
done

# Built Images
docker build -f Dockerfile-spark -t ${SPARK_IMAGE} ${LOC}
${LOC}/kafka/build-images.sh

docker image prune -f

# Scan final images
#for image in ${FINAL_IMAGES}
#do
#    docker scan ${image}
#done

# Push locally built images
#for image in ${BUILT_IMAGES}
#do
#    docker push ${image}
#done
