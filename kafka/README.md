# Docker Cluster For Kafka

Based on the docker work of [Wurstmeister](https://github.com/wurstmeister).

## Running The Cluster

````
. ../set-ip.sh
docker-compose up -d
````

## Command Line Client

Use an instance of the same kafka image to access the client tools.

````
docker run --rm -it --network kafka_default wurstmeister/kafka bash

kafka-topics.sh --bootstrap-server kafka:9092 --create --topic test
Created topic test.

kafka-topics.sh --bootstrap-server kafka:9092 --list
test

kafka-topics.sh --bootstrap-server kafka:9092 --describe
Topic: test     PartitionCount: 1       ReplicationFactor: 1    Configs: segment.bytes=1073741824
        Topic: test     Partition: 0    Leader: 1001    Replicas: 1001  Isr: 1001

exit
````

