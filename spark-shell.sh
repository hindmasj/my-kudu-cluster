#!/bin/bash

LOC=$(dirname $(readlink -f ${BASH_SOURCE[0]}))

export SPARK_LOCAL_IP=$(ip addr | awk '/inet .*/ {print $2}' | grep -v 127.0.0.1 | cut -d/ -f1 | tail -1)

/opt/spark/bin/spark-shell \
	--master local \
	--packages org.apache.kudu:kudu-spark2_2.11:1.13.0 \
	-I ${LOC}/kudu-spark.scala

