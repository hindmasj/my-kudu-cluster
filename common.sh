# Common settings for Kudu cluster scripts

COMPOSE=${LOC}/kudu-cluster.yml

PROJECT_REPOSITORY="stephenhindmarch/kudu-cluster"

DOCKER_IP=$(ip addr | grep eth0 | tail -1 | \
    awk '{split($2,a,"/");print a[1]}')
DOCKER_NETWORK=my-kudu-cluster_default
export DOCKER_IP DOCKER_NETWORK

KUDU_IMAGE=apache/kudu:latest
KUDU_MASTERS=kudu-master-0:7051,kudu-master-1:7151,kudu-master-2:7251
MASTER_CONTAINER=kudu-master
export KUDU_IMAGE KUDU_MASTERS MASTER_CONTAINER

IMPALA_CONTAINER=kudu-impala
IMPALA_IMAGE=apache/kudu:impala-latest
IMPALA_PORT_MAP="-p 21000:21000 -p 21050:21050 -p 25000:25000 -p 25010:25010 -p 25020:25020"
export IMPALA_CONTAINER IMPALA_IMAGE IMPALA_PORT_MAP

SPARK_BASE_IMAGE=bde2020/spark-base:latest
SPARK_IMAGE=${PROJECT_REPOSITORY}:spark
export SPARK_BASE_IMAGE SPARK_IMAGE

KAFKA_BASE_IMAGE=wurstmeister/kafka:latest
ZOOKEEPER_BASE_IMAGE=wurstmeister/zookeeper:latest
KAFKA_IMAGE=${PROJECT_REPOSITORY}:kafka
ZOOKEEPER_IMAGE=${PROJECT_REPOSITORY}:zookeeper
export KAFKA_BASE_IMAGE ZOOKEEPER_BASE_IMAGE KAFKA_IMAGE ZOOKEEPER_IMAGE
