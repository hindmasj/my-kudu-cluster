#!/bin/bash

LOC=$(dirname $(readlink -f ${BASH_SOURCE[0]}))

JAVA_VERSION=$(rpm -qf $(readlink -f $(which java)) --qf '%{VERSION}\n'| awk 'BEGIN{FS="."}{print $1}')
if [ -z "$JAVA_VERSION" ]
then
    echo "Java not found"
    exit 1
fi
if [ ${JAVA_VERSION} -ne 8 -a ${JAVA_VERSION} -ne 11 ]
then
    echo "Incompatible version of java (${JAVA_VERSION}) found"
    echo "You need Java 8 or 11 for spark"
    exit 2
fi

export SPARK_LOCAL_IP=$(ip addr | awk '/inet .*/ {print $2}' | grep -v 127.0.0.1 | cut -d/ -f1 | tail -1)

export SPARK_HOME=/opt/spark

. $SPARK_HOME/bin/load-spark-env.sh

$SPARK_HOME/bin/spark-shell \
	--master local \
	--packages org.apache.kudu:kudu-spark2_2.11:1.13.0 \
	-I ${LOC}/kudu-spark.scala "${@}"

